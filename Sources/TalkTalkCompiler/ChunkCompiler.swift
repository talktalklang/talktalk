//
//  ChunkCompiler.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/2/24.
//

import TalkTalkAnalysis
import TalkTalkBytecode
import TalkTalkSyntax

public class ChunkCompiler: AnalyzedVisitor {
	public typealias Value = Void

	// Tracks how deep we are in frames
	let scopeDepth: Int

	var module: CompilingModule

	// If this is a subchunk it has a parent compiler. We use this to resolve upvalues
	public var parent: ChunkCompiler?

	// Tracks local variable slots
	public var locals: [Variable]

	// Tracks which locals have been captured from parents
	public var captures: Set<Capture> = []

	// Tracks which locals have been captured by children
	public var capturedLocals: Set<Symbol> = []

	// Track which locals have been created in this scope
	public var localsCount = 1

	// Tracks how many upvalues we currently have
	public var upvalues: [(index: Byte, isLocal: Bool)] = []

	public init(module: CompilingModule, scopeDepth: Int = 0, parent: ChunkCompiler? = nil) {
		self.module = module
		self.scopeDepth = scopeDepth
		self.parent = parent
		self.locals = [.reserved(depth: scopeDepth)]
	}

	public func endScope(chunk: Chunk) {
		for i in 0 ..< locals.count {
			let local = locals[locals.count - i - 1]
			if local.depth <= scopeDepth { break }

			chunk.emit(opcode: .pop, line: 0)
		}
	}

	// MARK: Visitor methods

	public func visit(_ expr: AnalyzedArrayLiteralExpr, _ chunk: Chunk) throws {
		// Put the element values of this array onto the stack. We reverse it because the VM
		// builds up the array by popping values off
		for element in expr.exprsAnalyzed.reversed() {
			try element.accept(self, chunk)
		}

		chunk.emit(opcode: .initArray, line: expr.location.line)
		chunk.emit(.byte(Byte(expr.exprsAnalyzed.count)), line: expr.location.line)
	}

	public func visit(_: AnalyzedIdentifierExpr, _: Chunk) throws {
		// This gets handled by VarExpr
	}

	public func visit(_ expr: AnalyzedExprStmt, _ chunk: Chunk) throws {
		// Visit the actual expr
		try expr.exprAnalyzed.accept(self, chunk)

		if let funcExpr = expr.exprAnalyzed as? AnalyzedFuncExpr,
		   funcExpr.name != nil
		{
			// Don't pop named functions off the stack because we might need to reference
			// their name.
			return
		}

		switch expr.exitBehavior {
		case .pop:
			// Pop the expr off the stack because this is a statement so we don't care about the
			// return value
			// TODO: Do we need to pop if the expr stmt returns void?
			if expr.exprAnalyzed.inferenceType != .void {
				chunk.emit(opcode: .pop, line: expr.location.line)
			}
		case .return:
			// If this is the only statement in a block, we can sometimes implicitly return
			// its expr instead of just popping it (like in a function body). We don't want to
			// do this for things like if/while statements tho.
			chunk.emit(opcode: .returnValue, line: expr.location.line)
		case .none:
			() // Leave the value on the stack
		}
	}

	public func visit(_: AnalyzedImportStmt, _: Chunk) throws {
		// This is just an analysis thing
	}

	public func visit(_ expr: AnalyzedCallExpr, _ chunk: Chunk) throws {
		if case let .pattern(pattern) = expr.inferenceType {
			for (i, arg) in expr.argsAnalyzed.enumerated() {
				switch pattern.arguments[i] {
				case .value(_):
					try arg.accept(self, chunk)
				case .variable(let name, _):
					chunk.emit(.opcode(.binding), line: arg.location.line)
					chunk.emit(.symbol(.value(module.name, name)), line: arg.location.line)
				}
			}

			try expr.calleeAnalyzed.accept(self, chunk)

			// Call the callee
			chunk.emit(opcode: .call, line: expr.location.line)

			return
		}

		if expr.calleeAnalyzed is AnalyzedEnumMemberExpr {
			for arg in expr.argsAnalyzed {
				if let arg = arg.expr as? VarLetDecl {
					chunk.emit(.opcode(.binding), line: arg.location.line)
					chunk.emit(.symbol(.value(module.name, arg.name)), line: arg.location.line)
				} else {
					try arg.accept(self, chunk)
				}
			}

			try expr.calleeAnalyzed.accept(self, chunk)

			// Call the callee
			chunk.emit(opcode: .call, line: expr.location.line)

			return
		}

		// Put the function args on the stack
		for arg in expr.argsAnalyzed {
			try arg.expr.accept(self, chunk)
		}

		// Put the callee on the stack. This gets popped first. Then we can go and grab the args.
		try expr.calleeAnalyzed.accept(self, chunk)

		// Call the callee
		chunk.emit(opcode: .call, line: expr.location.line)
	}

	public func visit(_ expr: AnalyzedDefExpr, _ chunk: Chunk) throws {
		// Put the value onto the stack
		try expr.valueAnalyzed.accept(self, chunk)

		if expr.receiver is SubscriptExprSyntax {
			throw CompilerError.typeError("Setting via subscripts doesn't work yet.")
		}

		let variable = try resolveVariable(
			receiver: expr.receiverAnalyzed,
			chunk: chunk
		)

		guard let variable else {
			throw CompilerError.unknownIdentifier(
				expr.description + " in def expr at line: \(expr.location.start.line)"
			)
		}

		// If this is a member, we need to put the member's owner on the stack as well
		if let member = expr.receiverAnalyzed as? AnalyzedMemberExpr {
			try member.receiverAnalyzed.accept(self, chunk)
		}

		chunk.emit(opcode: variable.setter, line: expr.location.line)
		chunk.emit(variable.code, line: expr.location.line)

//		if variable.setter == .setUpvalue {
//			chunk.emit(opcode: .pop, line: expr.location.line)
//		}
	}

	public func visit(_ expr: AnalyzedErrorSyntax, _: Chunk) throws {
		throw CompilerError.analysisError(expr.message)
	}

	public func visit(_ expr: AnalyzedUnaryExpr, _ chunk: Chunk) throws {
		try expr.exprAnalyzed.accept(self, chunk)

		switch expr.op {
		case .bang:
			chunk.emit(opcode: .not, line: expr.location.line)
		case .minus:
			chunk.emit(opcode: .negate, line: expr.location.line)
		default:
			throw CompilerError.unreachable
		}
	}

	public func visit(_ expr: AnalyzedLiteralExpr, _ chunk: Chunk) throws {
		switch expr.value {
		case let .int(int):
			chunk.emit(constant: .int(.init(int)), line: expr.location.line)
		case let .bool(bool):
			chunk.emit(opcode: bool ? .true : .false, line: expr.location.line)
		case let .string(string):
			// Get the bytes
			chunk.emit(
				data: StaticData(kind: .string, bytes: string.utf8),
				line: expr.location.line
			)
		case .none:
			chunk.emit(opcode: .none, line: expr.location.line)
		}
	}

	public func visit(_ expr: AnalyzedVarExpr, _ chunk: Chunk) throws {
		guard
			let variable = try resolveVariable(
				receiver: expr,
				chunk: chunk
			)
		else {
			throw CompilerError.unknownIdentifier(expr.name + " in var expr at line: \(expr.location.start.line)")
		}

		chunk.emit(opcode: variable.getter, line: expr.location.line)
		chunk.emit(variable.code, line: expr.location.line)
	}

	public func visit(_ expr: AnalyzedBinaryExpr, _ chunk: Chunk) throws {
		let opcode: Opcode =
			switch expr.op {
			case .plus: .add
			case .equalEqual: .equal
			case .bangEqual: .notEqual
			case .less: .less
			case .lessEqual: .lessEqual
			case .greater: .greater
			case .greaterEqual: .greaterEqual
			case .minus: .subtract
			case .star: .multiply
			case .slash: .divide
			case .is: .is
			}

		try expr.rhsAnalyzed.accept(self, chunk)
		try expr.lhsAnalyzed.accept(self, chunk)

		chunk.emit(opcode: opcode, line: expr.location.line)
	}

	public func visit(_ expr: AnalyzedIfExpr, _ chunk: Chunk) throws {
		// Emit the condition
		try expr.conditionAnalyzed.accept(self, chunk)

		// Emit the jumpUnless opcode, and keep track of where we are in the code.
		// We need this location so we can go back and patch the locations after emitting
		// the else stuff.
		let thenJumpLocation = chunk.emit(jump: .jumpUnless, line: expr.condition.location.line)

		// Pop the condition off the stack
		chunk.emit(opcode: .pop, line: expr.condition.location.line)

		// Emit the consequence block
		try expr.consequenceAnalyzed.accept(self, chunk)

		// Emit the else jump, right after the consequence block. This is where we'll skip to
		// if the condition is false. If the condition was true, once the consequence block was
		// evaluated, we'll jump to past the alternative block.
		let elseJump = chunk.emit(jump: .jump, line: expr.alternativeAnalyzed.location.line)

		// Fill in the initial placeholder bytes now that we know how big the consequence block was
		try chunk.patchJump(thenJumpLocation)
		// Pop the condition off the stack (TODO: why again?)
		chunk.emit(opcode: .pop, line: expr.conditionAnalyzed.location.line)

		// Emit the alternative block
		try expr.alternativeAnalyzed.accept(self, chunk)

		// Fill in the else jump so we know how far to skip if the condition was true
		try chunk.patchJump(elseJump)
	}

	public func visit(_ expr: AnalyzedInitDecl, _ chunk: Chunk) throws {
		// Define the params for this init
		for parameter in expr.parametersAnalyzed.paramsAnalyzed {
			_ = defineLocal(
				name: parameter.name,
				compiler: self,
				chunk: chunk
			)
		}

		// Emit the init body
		try visit(expr.bodyAnalyzed, chunk)

		// End the scope, which pops locals
		endScope(chunk: chunk)

		// Add the instance to the top of the stack so it'll always be returned
		chunk.emit(opcode: .getLocal, line: UInt32(expr.location.end.line))
		chunk.emit(.symbol(.value(module.name, "self")), line: UInt32(expr.location.end.line))
		chunk.emit(opcode: .returnValue, line: UInt32(expr.location.end.line))

		_ = try module.addChunk(chunk)
	}

	public func visit(_ expr: AnalyzedFuncExpr, _ chunk: Chunk) throws {
		let functionChunk = Chunk(
			name: expr.name?.lexeme ?? expr.autoname,
			symbol: expr.symbol,
			parent: chunk,
			arity: Byte(expr.analyzedParams.params.count), depth: Byte(scopeDepth),
			path: chunk.path
		)
		let functionCompiler = ChunkCompiler(module: module, scopeDepth: scopeDepth + 1, parent: self)

		// Define the params for this function
		for parameter in expr.analyzedParams.paramsAnalyzed {
			_ = functionCompiler.defineLocal(
				name: parameter.name,
				compiler: functionCompiler,
				chunk: functionChunk
			)
		}

		if let name = expr.name?.lexeme {
			if module.moduleFunctionOffset(for: name) != nil {
				_ = try resolveVariable(named: name, symbol: expr.symbol, chunk: chunk)
			} else {
				// Define the function in its enclosing scope
				_ = defineLocal(
					name: name,
					compiler: self,
					chunk: chunk
				)
			}
		}

		// Emit the function body
		try functionCompiler.visit(expr.bodyAnalyzed, functionChunk)

		// End the scope, which pops or captures locals
		functionCompiler.endScope(chunk: functionChunk)

		// We always want to emit a return at the end of a function. If the function's return value
		// is void then we just emit returnVoid. Otherwise we emit returnValue which will grab the return
		// value from the top of the stack.
		let opcode: Opcode
		switch expr.inferenceType {
		case .function(_, .void):
			opcode = .returnVoid
		default:
			opcode = .returnValue
		}

		functionChunk.emit(opcode: opcode, line: UInt32(expr.location.end.line))

		// Store which locals this function has captured by children
		functionChunk.capturedLocals = functionCompiler.capturedLocals

		// Store which locals this function captures from parents
		functionChunk.captures = functionCompiler.captures

		let line = UInt32(expr.location.line)

		guard module.analysisModule.symbols[expr.symbol] != nil else {
			throw CompilerError.unknownIdentifier(expr.symbol.description)
		}

		_ = try module.addChunk(functionChunk)
		chunk.emitClosure(subchunk: expr.symbol, line: line)
	}

	public func visit(_ expr: AnalyzedBlockStmt, _ chunk: Chunk) throws {
		for expr in expr.stmtsAnalyzed {
			try expr.accept(self, chunk)
		}
	}

	public func visit(_ expr: AnalyzedWhileStmt, _ chunk: Chunk) throws {
		// This is where we return to if the condition is true
		let loopStart = chunk.code.count

		// Emit the condition
		try expr.conditionAnalyzed.accept(self, chunk)

		// Emit the jump for after the block for when the condition isn't true
		let exitJump = chunk.emit(jump: .jumpUnless, line: expr.condition.location.line)

		// Pop the condition off the stack
		chunk.emit(opcode: .pop, line: expr.condition.location.line)

		// Emit the body
		try expr.bodyAnalyzed.accept(self, chunk)

		// Jump back to the loop start
		chunk.emit(loop: loopStart, line: .init(expr.body.location.end.line))

		// Now that we know how long the body is (including the jump back), we can patch our jump
		// with the location to jump to in the event that the condition is false
		try chunk.patchJump(exitJump)

		chunk.emit(opcode: .pop, line: expr.condition.location.line)
	}

	public func visit(_: AnalyzedParamsExpr, _: Chunk) throws {}

	public func visit(_: AnalyzedParam, _: Chunk) throws {}

	public func visit(_ expr: AnalyzedReturnStmt, _ chunk: Chunk) throws {
		try expr.valueAnalyzed?.accept(self, chunk)

		if expr.valueAnalyzed != nil {
			chunk.emit(opcode: .returnValue, line: expr.location.line)
		} else {
			chunk.emit(opcode: .returnVoid, line: expr.location.line)
		}
	}

	public func visit(_ expr: AnalyzedMemberExpr, _ chunk: Chunk) throws {
		try expr.receiverAnalyzed.accept(self, chunk)

		// Emit the getter
		chunk.emit(opcode: .getProperty, line: expr.location.line)

		// Emit the property's slot
		let symbol = if let property = expr.memberAnalyzed as? Property {
			property.symbol
		} else if let method = expr.memberAnalyzed as? Method {
			method.symbol
		} else {
			throw CompilerError.unknownIdentifier("Member not found for \(expr.receiverAnalyzed.description): \(expr.memberAnalyzed)")
		}

		chunk.emit(.symbol(symbol), line: expr.location.line)

		// Emit the property's optionset
		var options = PropertyOptions()
		if expr.memberAnalyzed is Method {
			options.insert(.isMethod)
		}

		chunk.emit(.byte(options.rawValue), line: expr.location.line)
	}

	public func visit(_ expr: AnalyzedDeclBlock, _ chunk: Chunk) throws {
		for decl in expr.declsAnalyzed {
			try decl.accept(self, chunk)
		}
	}

	public func visit(_ expr: AnalyzedTypeExpr, _ chunk: Chunk) throws {
		if let symbol = resolveStruct(named: expr.symbol) {
			chunk.emit(opcode: .getStruct, line: expr.location.line)
			chunk.emit(.symbol(symbol), line: expr.location.line)
		} else {
//			let type = expr.environment.type(named: expr.identifier.lexeme)
			throw CompilerError.unknownIdentifier("could not find struct named: \(expr.identifier.lexeme)")
		}
	}

	public func visit(_ expr: AnalyzedStructDecl, _ chunk: Chunk) throws {
		let name = expr.name
		var structType = Struct(name: name, propertyCount: expr.structType.properties.count)

		for decl in expr.bodyAnalyzed.declsAnalyzed {
			switch decl {
			case let decl as AnalyzedInitDecl:
				if expr.structType.methods["init"]?.isSynthetic == true {
					continue
				}

				let symbol = Symbol.method(module.name, name, "init", decl.params.params.map {
					module.analysisModule.inferenceContext.lookup(syntax: $0)?.description ?? "_"
				})

				let declCompiler = ChunkCompiler(module: module, scopeDepth: scopeDepth + 1)
				let declChunk = Chunk(
					name: symbol.description,
					symbol: symbol,
					parent: chunk,
					arity: Byte(decl.params.count),
					depth: Byte(scopeDepth),
					path: chunk.path
				)

				// Define the actual params for this initializer
				for parameter in decl.parametersAnalyzed.paramsAnalyzed {
					_ = declCompiler.defineLocal(
						name: parameter.name,
						compiler: declCompiler,
						chunk: declChunk
					)
				}

				// Emit the init body
				for expr in decl.bodyAnalyzed.stmtsAnalyzed {
					try expr.accept(declCompiler, declChunk)
				}

				// End the scope, which pops locals
				declCompiler.endScope(chunk: declChunk)

				// Make sure the instance is at the top of the stack and return it
				declChunk.emit(opcode: .getLocal, line: UInt32(decl.location.end.line))
				declChunk.emit(.symbol(.value(module.name, "self")), line: UInt32(decl.location.end.line))
				declChunk.emit(opcode: .returnValue, line: UInt32(decl.location.end.line))

				guard let analysisMethod = expr.structType.methods["init"] else {
					throw CompilerError.typeError("No `init` found for \(expr.name)")
				}

				module.compiledChunks[analysisMethod.symbol] = declChunk
				structType.initializer = analysisMethod.symbol
			case let decl as AnalyzedFuncExpr:
				guard let declName = decl.name?.lexeme else {
					throw CompilerError.unknownIdentifier(decl.description)
				}

				let symbol = Symbol.method(module.name, name, declName, decl.params.params.map {
					module.analysisModule.inferenceContext.lookup(syntax: $0)?.description ?? "_"
				})

				let declCompiler = ChunkCompiler(module: module, scopeDepth: scopeDepth + 1)
				let declChunk = Chunk(
					name: symbol.description,
					symbol: symbol,
					parent: chunk,
					arity: Byte(decl.params.count),
					depth: Byte(scopeDepth),
					path: chunk.path
				)

				// Define the params for this function
				for parameter in decl.analyzedParams.paramsAnalyzed {
					_ = declCompiler.defineLocal(
						name: parameter.name,
						compiler: declCompiler,
						chunk: declChunk
					)
				}

				// Emit the body
				for expr in decl.bodyAnalyzed.stmtsAnalyzed {
					try expr.accept(declCompiler, declChunk)
				}

				// End the scope, which pops locals
				declCompiler.endScope(chunk: declChunk)

				let opcode: Opcode
				switch decl.inferenceType {
				case .function(_, .void):
					opcode = .returnVoid
				default:
					opcode = .returnValue
				}

				declChunk.emit(opcode: opcode, line: UInt32(decl.location.end.line))

				guard let analysisMethod = expr.structType.methods[declName] else {
					throw CompilerError.analysisError("Missing analyzer method for \(name).\(declName)")
				}

				module.compiledChunks[analysisMethod.symbol] = declChunk
			case is AnalyzedVarDecl: ()
			case is AnalyzedLetDecl: ()
			default:
				throw CompilerError.typeError("Unknown decl: \(decl)")
			}
		}

		guard let initializer = expr.structType.methods["init"] else {
			throw CompilerError.unknownIdentifier("Missing init for \(name)")
		}

		if initializer.isSynthetic {
			structType.initializer = initializer.symbol
			let chunk = synthesizeInit(for: expr.structType)
			module.compiledChunks[initializer.symbol] = chunk
		}

		module.structs[expr.symbol] = structType
	}

	public func visit(_: AnalyzedGenericParams, _: Chunk) throws {
		// No need to emit any code here because generic params are just used by the analyzer... for now?
	}

	public func visit(_ expr: AnalyzedVarDecl, _ chunk: Chunk) throws {
		if expr.environment.isModuleScope {
			// If it's at module scope, that means it's a global, which gets lazily initialized
			let variable = try emitLazyInitializer(for: expr, in: chunk)

			if let value = expr.valueAnalyzed {
				try value.accept(self, chunk)
				chunk.emit(opcode: .setModuleValue, line: value.location.line)
				chunk.emit(variable.code, line: value.location.line)
			}

			return
		}

		let variable = defineLocal(
			name: expr.name,
			compiler: self,
			chunk: chunk
		)

		if let value = expr.valueAnalyzed {
			try value.accept(self, chunk)
			chunk.emit(opcode: .setLocal, line: value.location.line)
			chunk.emit(variable.code, line: value.location.line)
		}
	}

	public func visit(_ expr: AnalyzedLetDecl, _ chunk: Chunk) throws {
		if expr.environment.isModuleScope {
			// If it's at module scope, that means it's a global, which gets lazily initialized
			let variable = try emitLazyInitializer(for: expr, in: chunk)

			if let value = expr.valueAnalyzed {
				try value.accept(self, chunk)
				chunk.emit(opcode: .setModuleValue, line: value.location.line)
				chunk.emit(variable.code, line: value.location.line)
			}

			return
		}

		let variable = defineLocal(
			name: expr.name,
			compiler: self,
			chunk: chunk
		)

		if let value = expr.valueAnalyzed {
			try value.accept(self, chunk)
			chunk.emit(opcode: .setLocal, line: value.location.line)
			chunk.emit(variable.code, line: value.location.line)
		}
	}

	public func visit(_ expr: AnalyzedIfStmt, _ chunk: Chunk) throws {
		// Emit the condition
		try expr.conditionAnalyzed.accept(self, chunk)

		// Emit the jumpUnless opcode, and keep track of where we are in the code.
		// We need this location so we can go back and patch the locations after emitting
		// the else stuff.
		let thenJumpLocation = chunk.emit(jump: .jumpUnless, line: expr.condition.location.line)

		// Pop the condition off the stack
		chunk.emit(opcode: .pop, line: expr.condition.location.line)

		// Emit the consequence block
		try expr.consequenceAnalyzed.accept(self, chunk)

		// Emit the else jump, right after the consequence block. This is where we'll skip to
		// if the condition is false. If the condition was true, once the consequence block was
		// evaluated, we'll jump to past the alternative block.
		let elseJump = chunk.emit(jump: .jump, line: UInt32(expr.consequence.location.end.line))

		// Fill in the initial placeholder bytes now that we know how big the consequence block was
		try chunk.patchJump(thenJumpLocation)

		// Pop the condition off the stack
		chunk.emit(opcode: .pop, line: expr.condition.location.line)

		// Emit the alternative block
		if let alternativeAnalyzed = expr.alternativeAnalyzed {
			try alternativeAnalyzed.accept(self, chunk)
		}

		// Fill in the else jump so we know how far to skip if the condition was true
		try chunk.patchJump(elseJump)
	}

	public func visit(_: AnalyzedStructExpr, _: Chunk) throws {}

	public func visit(_ expr: AnalyzedSubscriptExpr, _ chunk: Chunk) throws {
		// Emit the args
		for arg in expr.argsAnalyzed {
			try arg.expr.accept(self, chunk)
		}

		// Put the receiver at the top of the stack
		try expr.receiverAnalyzed.accept(self, chunk)
		chunk.emit(opcode: .get, line: expr.location.line)
	}

	public func visit(_: AnalyzedDictionaryLiteralExpr, _: Chunk) throws {
		// Store the values
//		for element in expr.elementsAnalyzed {
//			try visit(element, chunk)
//		}

//		let dictSlot = module.analysisModule.symbols[.struct("Standard", "Dictionary")]!.slot
//		chunk.emit(opcode: .getStruct, line: expr.location.line)
//		chunk.emit(byte: Byte(dictSlot), line: expr.location.line)
//		chunk.emit(opcode: .call, line: expr.location.line)

		// Emit the count so we can init enough storage
//		chunk.emit(byte: Byte(expr.elements.count), line: expr.location.line)
	}

	public func visit(_ expr: AnalyzedDictionaryElementExpr, _ chunk: Chunk) throws {
		try expr.keyAnalyzed.accept(self, chunk)
		try expr.valueAnalyzed.accept(self, chunk)
	}

	public func visit(_: AnalyzedProtocolDecl, _: Chunk) throws {
		// TODO: this
	}

	public func visit(_: AnalyzedProtocolBodyDecl, _: Chunk) throws {
		// TODO: this
	}

	public func visit(_: AnalyzedFuncSignatureDecl, _: Chunk) throws {
		// TODO: this
	}

	public func visit(_ expr: AnalyzedEnumDecl, _: Chunk) throws {
		let enumType = Enum(
			name: expr.nameToken.lexeme,
			cases: expr.casesAnalyzed.reduce(into: [:]) { res, kase in
				res[.property(module.name, kase.enumName, kase.nameToken.lexeme)] = EnumCase(
					type: expr.nameToken.lexeme,
					name: kase.nameToken.lexeme,
					arity: kase.attachedTypes.count
				)
			}
		)

		module.enums[expr.symbol] = enumType
	}

	public func visit(_ expr: AnalyzedEnumCaseDecl, _ chunk: Chunk) throws {
		guard let enumSymbol = module.analysisModule.moduleEnum(named: expr.enumName)?.symbol,
		      module.analysisModule.symbols[enumSymbol] != nil
		else {
			throw CompilerError.unknownIdentifier(expr.nameToken.lexeme)
		}

		_ = expr.inferenceType

		chunk.emit(opcode: .getEnum, line: expr.location.line)
	}

	public func visit(_ expr: AnalyzedMatchStatement, _ chunk: Chunk) throws {
		let matchSymbol = Symbol.function(module.name, "match#\(expr.id)", [])

		let matchChunk = Chunk(
			name: expr.description,
			symbol: matchSymbol,
			parent: chunk,
			arity: 0,
			depth: Byte(scopeDepth),
			path: chunk.path
		)

		let matchCompiler = ChunkCompiler(module: module, scopeDepth: scopeDepth + 1, parent: self)

		chunk.emit(opcode: .matchBegin, line: expr.location.line)
		chunk.emit(.symbol(matchSymbol), line: expr.location.line)

		var caseJumps: [Int] = []
		var endJumps: [Int] = []

		// Emit the cases for comparison with the target pattern
		for kase in expr.casesAnalyzed {
			try PatternCompiler(
				target: expr.targetAnalyzed,
				caseStatement: kase,
				compiler: matchCompiler,
				chunk: matchChunk
			).compileCase()

			caseJumps.append(
				matchChunk.emit(jump: .matchCase, line: kase.location.line)
			)

			// Pop bool result off the stack
			matchChunk.emit(.opcode(.pop), line: kase.location.line)
		}

		// Emit the bodies that get jumped to from cases
		for (i, kase) in expr.casesAnalyzed.enumerated() {
			try matchChunk.patchJump(caseJumps[i])

			try PatternCompiler(
				target: expr.targetAnalyzed,
				caseStatement: kase,
				compiler: matchCompiler,
				chunk: matchChunk
			).compileBody()

			endJumps.append(
				matchChunk.emit(jump: .jump, line: kase.bodyAnalyzed.last?.location.line ?? kase.location.line)
			)
		}

		for jump in endJumps {
			try matchChunk.patchJump(jump)
		}

		matchChunk.emit(opcode: .endInline, line: expr.location.line)

		module.compiledChunks[matchSymbol] = matchChunk
	}

	public func visit(_: AnalyzedCaseStmt, _: Chunk) throws {
		// Handled by match stmt
	}

	public func visit(_ expr: AnalyzedEnumMemberExpr, _ chunk: Chunk) throws {
		guard case let .enumCase(enumCase) = expr.inferenceType else {
			throw CompilerError.unknownIdentifier("\(expr.description)")
		}

		chunk.emit(opcode: .getEnum, line: expr.location.line)
		chunk.emit(.symbol(.enum(module.name, enumCase.typeName)), line: expr.location.line)
		chunk.emit(.opcode(.getProperty), line: expr.location.line)
		chunk.emit(.symbol(.property(module.name, enumCase.typeName, enumCase.name)), line: expr.location.line)
		chunk.emit(.byte(0), line: expr.location.line) // Emit empty property options
	}

	// GENERATOR_INSERTION

	// MARK: Helpers

	// Lookup the variable by name. If we've got it in our locals, just return the slot
	// for that variable. If we don't, search parent chunks to see if they've got it. If
	// they do, we've got an upvalue.
	public func resolveVariable(receiver: any AnalyzedSyntax, chunk: Chunk) throws -> Variable? {
		var varName: String?
		var symbol: Symbol?

		if let syntax = receiver as? AnalyzedVarExpr {
			varName = syntax.name
			symbol = syntax.symbol
		} else if let syntax = receiver as? any AnalyzedVarLetDecl {
			varName = syntax.name
			symbol = syntax.symbol
		}

		if let varName, let variable = try resolveVariable(named: varName, symbol: symbol, chunk: chunk) {
			return variable
		}

		if let syntax = receiver as? AnalyzedMemberExpr,
		   let property = syntax.memberAnalyzed as? Property
		{
			return Variable(
				name: syntax.property,
				code: .symbol(property.symbol),
				depth: scopeDepth,
				getter: .getProperty,
				setter: .setProperty
			)
		}

		return nil
	}

	func resolveVariable(named varName: String, symbol: Symbol?, chunk _: Chunk) throws -> Variable? {
		if varName == "self" {
			return Variable(
				name: varName,
				code: .symbol(.value(module.name, "self")),
				depth: scopeDepth,
				getter: .getLocal,
				setter: .setLocal
			)
		}

		if let local = resolveLocal(named: varName) {
			return Variable(
				name: varName,
				code: local,
				depth: scopeDepth,
				getter: .getLocal,
				setter: .setLocal
			)
		}

		if let capture = try resolveCapture(named: varName) {
			return Variable(
				name: varName,
				code: .capture(capture),
				depth: scopeDepth,
				getter: .getCapture,
				setter: .setCapture
			)
		}

		if let symbol = resolveEnum(named: varName) {
			return Variable(
				name: varName,
				code: .symbol(symbol),
				depth: scopeDepth,
				getter: .getEnum,
				setter: .getEnum
			)
		}

		if let symbol = resolveModuleFunction(named: varName) {
			return Variable(
				name: varName,
				code: .symbol(symbol),
				depth: scopeDepth,
				getter: .getModuleFunction,
				setter: .setModuleFunction
			)
		}

		if let symbol = resolveModuleValue(named: varName) {
			return Variable(
				name: varName,
				code: .symbol(symbol),
				depth: scopeDepth,
				getter: .getModuleValue,
				setter: .setModuleValue
			)
		}

		if let symbol, case .struct = symbol.kind {
			return Variable(
				name: varName,
				code: .symbol(symbol),
				depth: scopeDepth,
				getter: .getStruct,
				setter: .setStruct
			)
		}

		if let fn = BuiltinFunction.list.first(
			where: { $0.name == varName }
		) {
			return Variable(
				name: varName,
				code: .symbol(.function("[builtin]", varName, fn.parameters)),
				depth: scopeDepth,
				getter: .getBuiltin,
				setter: .setBuiltin
			)
		}

		return nil
	}

	// Just look up the var in our locals
	public func resolveLocal(named name: String) -> Code? {
		if let variable = locals.first(where: { $0.name == name }) {
			return variable.code
		}

		return nil
	}

//	// Search parent chunks for the variable
//	private func resolveUpvalue(named name: String, chunk: Chunk) -> Symbol? {
//		guard let parent else { return nil }
//
//		// If our immediate parent has the variable, we return an upvalue.
//		if let local = parent.resolveLocal(named: name) {
//			// Since it's in the immediate parent, we mark the upvalue as captured.
//			parent.captures.append(name)
//			return addUpvalue(local, isLocal: true, name: name, chunk: chunk)
//		}
//
//		// Check for upvalues in the parent. We don't need to mark the upvalue where it's found
//		// as captured since the immediate child of the owning scope will handle that in its
//		// resolveUpvalue call.
//		if let local = parent.resolveUpvalue(named: name, chunk: chunk) {
//			return addUpvalue(local, isLocal: false, name: name, chunk: chunk)
//		}
//
//		return nil
//	}

	private func resolveCapture(named name: String, depth: Int = 0) throws -> Capture? {
		guard let parent else { return nil }

		if case let .symbol(local) = parent.resolveLocal(named: name) {
			parent.capturedLocals.insert(local)

			return addCapture(local, name: name, depth: depth + 1)
		}

		return try parent.resolveCapture(named: name, depth: depth + 1)
	}

	func addCapture(_ symbol: Symbol, name: String, depth: Int) -> Capture {
		let capture = Capture(name: name, symbol: symbol, location: .stack(depth))
		captures.insert(capture)
		return capture
	}

	private func resolveEnum(named name: String) -> Symbol? {
		if module.analysisModule.lookup(symbol: .enum(name)) != nil {
			return .enum(module.name, name)
		}

		return nil
	}

	// Check the CompilingModule for a global function.
	private func resolveModuleFunction(named name: String) -> Symbol? {
		if let moduleFunc = module.analysisModule.moduleFunctions.first(where: { $0.key == name }) {
			return moduleFunc.value.symbol
		}

		return nil
	}

	// Check CompilingModule for a global value
	private func resolveModuleValue(named name: String) -> Symbol? {
		if let value = module.analysisModule.moduleValue(named: name) {
			return value.symbol
		}

		return nil
	}

	// Check CompilationModule for a global struct
	private func resolveStruct(named symbol: Symbol) -> Symbol? {
		guard case .struct = symbol.kind else {
			return nil
		}

		if module.analysisModule.symbols[symbol] != nil {
			return symbol
		}

		return nil
	}

	private func emitLazyInitializer(for expr: any AnalyzedVarLetDecl, in chunk: Chunk) throws -> Variable {
		// If this is a global module value, we want to evaluate it lazily. This is nice because
		// it doesn't incur startup overhead as well as lets us not worry so much about the order
		// in which files are evaluated.
		//
		// We save a lil chunk that initializes the value along with the module that can get called
		// when the global is referenced to set the initial value.
		guard let variable = try resolveVariable(receiver: expr, chunk: chunk), let symbol = expr.symbol else {
			throw CompilerError.unknownIdentifier(expr.nameToken.lexeme)
		}

		let initializerChunk = Chunk(name: "$initialize_\(variable.name)", symbol: symbol, path: chunk.path)
		let initializerCompiler = ChunkCompiler(module: module)

		// Emit actual value initialization into the chunk
		try expr.valueAnalyzed?.accept(initializerCompiler, initializerChunk)

		// Set the module value so it can be used going forward
		initializerChunk.emit(opcode: .setModuleValue, line: expr.location.line)
		initializerChunk.emit(variable.code, line: expr.location.line)

		// Return the actual value
		initializerChunk.emit(opcode: .getModuleValue, line: expr.location.line)
		initializerChunk.emit(variable.code, line: expr.location.line)

		// Return from the initialization chunk
		initializerChunk.emit(opcode: .returnValue, line: expr.location.line)

		module.valueInitializers[symbol] = initializerChunk

		return variable
	}

	func defineLocal(
		name: String,
		compiler: ChunkCompiler,
		chunk: Chunk
	) -> Variable {
		let variable = Variable(
			name: name,
			code: .symbol(.value(module.name, name)),
			depth: compiler.scopeDepth,
			getter: .getLocal,
			setter: .setLocal
		)

		chunk.locals.append(.value(module.name, name))
		compiler.locals.append(variable)
		return variable
	}

//	private func addUpvalue(_ index: Byte, isLocal: Bool, name: String, chunk: Chunk) -> Symbol {
//		// If we've already got it, return it
//		for upvalue in upvalues {
//			if upvalue.index == index, upvalue.isLocal {
//				return Byte(i)
//			}
//		}
//
//		// Otherwise add a new one
//		upvalues.append((index: index, isLocal: isLocal))
//		chunk.upvalueNames.append(name)
//
//		return Byte(upvalues.count - 1)
//	}

	private func synthesizeInit(for structType: StructType) -> Chunk {
		let params = Array(structType.properties.keys)
		let symbol = Symbol.method(
			module.name, structType.name ?? "<struct \(structType.id)>",
			"init",
			params
		)
		let chunk = Chunk(
			name: symbol.description,
			symbol: symbol,
			parent: nil,
			arity: Byte(params.count),
			depth: Byte(scopeDepth),
			path: "<init>"
		)

		let compiler = ChunkCompiler(module: module)

		// Define the params for this function
		var variables: [(Variable, Property)] = []
		for (name, property) in structType.properties {
			variables.append((compiler.defineLocal(
				name: name,
				compiler: compiler,
				chunk: chunk
			), property))
		}

		for (variable, property) in variables {
			// Put the parameter value onto the stack
			chunk.emit(opcode: .getLocal, line: 9999)
			chunk.emit(variable.code, line: 9999)

			// Get self
			chunk.emit(opcode: .getLocal, line: 9999)
			chunk.emit(.symbol(.value(module.name, "self")), line: 9999)

			// Set the property on self
			chunk.emit(opcode: .setProperty, line: 9999)
			chunk.emit(.symbol(property.symbol), line: 9999)
		}

		compiler.endScope(chunk: chunk)
		chunk.emit(opcode: .returnValue, line: 9999)

		return chunk
	}
}
