//
//  ChunkCompiler.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/2/24.
//

import TalkTalkAnalysis
import TalkTalkBytecode
import TalkTalkSyntax
import TypeChecker

public class ChunkCompiler: Visitor {
	public typealias Value = Void

	// Tracks how deep we are in frames
	let scopeDepth: Int

	let inferenceContext: InferenceContext

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

	public var symbols: SymbolGenerator

	public init(module: CompilingModule, scopeDepth: Int = 0, parent: ChunkCompiler? = nil) {
		self.module = module
		self.scopeDepth = scopeDepth
		self.parent = parent
		self.locals = [.reserved(depth: scopeDepth)]
		self.symbols = SymbolGenerator(moduleName: module.name, parent: nil)
	}

	public func endScope(chunk: Chunk) {
		for i in 0 ..< locals.count {
			let local = locals[locals.count - i - 1]
			if local.depth <= scopeDepth { break }

			chunk.emit(opcode: .pop, line: 0)
		}
	}

	func typeOf(_ syntax: any Syntax) throws -> InferenceType {
		try inferenceContext.type(syntax)
	}

	// MARK: Visitor methods

	public func visit(_ expr: ArrayLiteralExprSyntax, _ chunk: Chunk) throws {
		// Put the element values of this array onto the stack. We reverse it because the VM
		// builds up the array by popping values off
		for element in expr.exprs.reversed() {
			try element.accept(self, chunk)
		}

		chunk.emit(opcode: .initArray, line: expr.location.line)
		chunk.emit(.byte(Byte(expr.exprs.count)), line: expr.location.line)
	}

	public func visit(_: IdentifierExprSyntax, _: Chunk) throws {
		// This gets handled by VarExpr
	}

	public func visit(_ expr: ExprStmtSyntax, _ chunk: Chunk) throws {
		// Visit the actual expr
		try expr.expr.accept(self, chunk)

		if let funcExpr = expr.expr as? FuncExpr,
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
			if expr.expr.inferenceType != .void {
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

	public func visit(_: ImportStmtSyntax, _: Chunk) throws {
		// This is just an analysis thing
	}

	public func visit(_ expr: CallExprSyntax, _ chunk: Chunk) throws {
		if case let .pattern(pattern) = try typeOf(expr) {
			for (i, arg) in expr.args.enumerated() {
				switch pattern.arguments[i] {
				case .value:
					try arg.accept(self, chunk)
				case let .variable(name, _):
					chunk.emit(.opcode(.binding), line: arg.location.line)
					chunk.emit(.symbol(.value(module.name, name)), line: arg.location.line)
				}
			}

			try expr.callee.accept(self, chunk)

			// Call the callee
			chunk.emit(opcode: .call, line: expr.location.line)

			return
		}

		if expr.callee is EnumMemberExpr {
			for arg in expr.args {
				if let arg = arg.value as? VarLetDecl {
					chunk.emit(.opcode(.binding), line: arg.location.line)
					chunk.emit(.symbol(.value(module.name, arg.name)), line: arg.location.line)
				} else {
					try arg.accept(self, chunk)
				}
			}

			try expr.callee.accept(self, chunk)

			// Call the callee
			chunk.emit(opcode: .call, line: expr.location.line)

			return
		}

		// Put the function args on the stack
		for arg in expr.args {
			try arg.value.accept(self, chunk)
		}

		// Put the callee on the stack. This gets popped first. Then we can go and grab the args.
		try expr.callee.accept(self, chunk)

		// Call the callee
		chunk.emit(opcode: .call, line: expr.location.line)
	}

	public func visit(_ expr: DefExprSyntax, _ chunk: Chunk) throws {
		// Put the value onto the stack
		try expr.value.accept(self, chunk)

		if expr.receiver is SubscriptExprSyntax {
			throw CompilerError.typeError("Setting via subscripts doesn't work yet.")
		}

		let variable = try resolveVariable(
			receiver: expr.receiver,
			chunk: chunk
		)

		guard let variable else {
			throw CompilerError.unknownIdentifier(
				expr.description + " in def expr at line: \(expr.location.start.line)"
			)
		}

		// If this is a member, we need to put the member's owner on the stack as well
		if let member = expr.receiver as? MemberExpr {
			try member.accept(self, chunk)
		}

		chunk.emit(opcode: variable.setter, line: expr.location.line)
		chunk.emit(variable.code, line: expr.location.line)

//		if variable.setter == .setUpvalue {
//			chunk.emit(opcode: .pop, line: expr.location.line)
//		}
	}

	public func visit(_ expr: ParseErrorSyntax, _: Chunk) throws {
		throw CompilerError.analysisError(expr.message)
	}

	public func visit(_ expr: UnaryExprSyntax, _ chunk: Chunk) throws {
		try expr.expr.accept(self, chunk)

		switch expr.op {
		case .bang:
			chunk.emit(opcode: .not, line: expr.location.line)
		case .minus:
			chunk.emit(opcode: .negate, line: expr.location.line)
		default:
			throw CompilerError.unreachable
		}
	}

	public func visit(_ expr: LiteralExprSyntax, _ chunk: Chunk) throws {
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

	public func visit(_ expr: VarExprSyntax, _ chunk: Chunk) throws {
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

	public func visit(_ expr: BinaryExprSyntax, _ chunk: Chunk) throws {
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

		try expr.rhs.accept(self, chunk)
		try expr.lhs.accept(self, chunk)

		chunk.emit(opcode: opcode, line: expr.location.line)
	}

	public func visit(_ expr: IfExprSyntax, _ chunk: Chunk) throws {
		// Emit the condition
		try expr.condition.accept(self, chunk)

		// Emit the jumpUnless opcode, and keep track of where we are in the code.
		// We need this location so we can go back and patch the locations after emitting
		// the else stuff.
		let thenJumpLocation = chunk.emit(jump: .jumpUnless, line: expr.condition.location.line)

		// Pop the condition off the stack
		chunk.emit(opcode: .pop, line: expr.condition.location.line)

		// Emit the consequence block
		try expr.consequence.accept(self, chunk)

		// Emit the else jump, right after the consequence block. This is where we'll skip to
		// if the condition is false. If the condition was true, once the consequence block was
		// evaluated, we'll jump to past the alternative block.
		let elseJump = chunk.emit(jump: .jump, line: expr.alternative.location.line)

		// Fill in the initial placeholder bytes now that we know how big the consequence block was
		try chunk.patchJump(thenJumpLocation)
		// Pop the condition off the stack (TODO: why again?)
		chunk.emit(opcode: .pop, line: expr.condition.location.line)

		// Emit the alternative block
		try expr.alternative.accept(self, chunk)

		// Fill in the else jump so we know how far to skip if the condition was true
		try chunk.patchJump(elseJump)
	}

	public func visit(_ expr: InitDeclSyntax, _ chunk: Chunk) throws {
		// Define the params for this init
		for parameter in expr.params.params {
			_ = defineLocal(
				name: parameter.name,
				compiler: self,
				chunk: chunk
			)
		}

		// Emit the init body
		try visit(expr.body, chunk)

		// End the scope, which pops locals
		endScope(chunk: chunk)

		// Add the instance to the top of the stack so it'll always be returned
		chunk.emit(opcode: .getLocal, line: UInt32(expr.location.end.line))
		chunk.emit(.symbol(.value(module.name, "self")), line: UInt32(expr.location.end.line))
		chunk.emit(opcode: .returnValue, line: UInt32(expr.location.end.line))

		_ = try module.addChunk(chunk)
	}

	public func visit(_ expr: FuncExprSyntax, _ chunk: Chunk) throws {
		let symbol = try typeOf(expr).symbol(in: symbols, name: expr.autoname, source: .internal)

		let functionChunk = Chunk(
			name: expr.name?.lexeme ?? expr.autoname,
			symbol: symbol,
			parent: chunk,
			arity: Byte(expr.params.params.count), depth: Byte(scopeDepth),
			path: chunk.path
		)
		let functionCompiler = ChunkCompiler(module: module, scopeDepth: scopeDepth + 1, parent: self)

		// Define the params for this function
		for parameter in expr.params.params {
			_ = functionCompiler.defineLocal(
				name: parameter.name,
				compiler: functionCompiler,
				chunk: functionChunk
			)
		}

		if let name = expr.name?.lexeme {
			if module.moduleFunctionOffset(for: name) != nil {
				_ = try resolveVariable(named: name, symbol: symbol, chunk: chunk)
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
		try functionCompiler.visit(expr.body, functionChunk)

		// End the scope, which pops or captures locals
		functionCompiler.endScope(chunk: functionChunk)

		// We always want to emit a return at the end of a function. If the function's return value
		// is void then we just emit returnVoid. Otherwise we emit returnValue which will grab the return
		// value from the top of the stack.
		let opcode: Opcode = switch try typeOf(expr) {
		case .function(_, .void):
			.returnVoid
		default:
			.returnValue
		}

		functionChunk.emit(opcode: opcode, line: UInt32(expr.location.end.line))

		// Store which locals this function has captured by children
		functionChunk.capturedLocals = functionCompiler.capturedLocals

		// Store which locals this function captures from parents
		functionChunk.captures = functionCompiler.captures

		let line = UInt32(expr.location.line)

		_ = try module.addChunk(functionChunk)
		chunk.emitClosure(subchunk: symbol, line: line)
	}

	public func visit(_ expr: BlockStmtSyntax, _ chunk: Chunk) throws {
		for expr in expr.stmts {
			try expr.accept(self, chunk)
		}
	}

	public func visit(_ expr: WhileStmtSyntax, _ chunk: Chunk) throws {
		// This is where we return to if the condition is true
		let loopStart = chunk.code.count

		// Emit the condition
		try expr.condition.accept(self, chunk)

		// Emit the jump for after the block for when the condition isn't true
		let exitJump = chunk.emit(jump: .jumpUnless, line: expr.condition.location.line)

		// Pop the condition off the stack
		chunk.emit(opcode: .pop, line: expr.condition.location.line)

		// Emit the body
		try expr.body.accept(self, chunk)

		// Jump back to the loop start
		chunk.emit(loop: loopStart, line: .init(expr.body.location.end.line))

		// Now that we know how long the body is (including the jump back), we can patch our jump
		// with the location to jump to in the event that the condition is false
		try chunk.patchJump(exitJump)

		chunk.emit(opcode: .pop, line: expr.condition.location.line)
	}

	public func visit(_: ParamsExprSyntax, _: Chunk) throws {}

	public func visit(_: ParamSyntax, _: Chunk) throws {}

	public func visit(_ expr: ReturnStmtSyntax, _ chunk: Chunk) throws {
		try expr.value?.accept(self, chunk)

		if expr.value != nil {
			chunk.emit(opcode: .returnValue, line: expr.location.line)
		} else {
			chunk.emit(opcode: .returnVoid, line: expr.location.line)
		}
	}

	public func visit(_ expr: MemberExprSyntax, _ chunk: Chunk) throws {
		let type = try typeOf(expr)

		try expr.receiver?.accept(self, chunk)

//		// Emit the property's slot
//		let symbol = if let property = expr.member as? Property {
//			property.symbol
//		} else if let method = expr.member as? Method {
//			method.symbol
//		} else {
//			throw CompilerError.unknownIdentifier("Member not found for \(expr.receiver.description): \(expr.member)")
//		}
//
//		// Emit the getter
//		chunk.emit(opcode: .getProperty, line: expr.location.line)
//		chunk.emit(.symbol(symbol), line: expr.location.line)
//
//		// Emit the property's optionset
//		var options = PropertyOptions()
//		if expr.member is Method {
//			options.insert(.isMethod)
//		}

//		chunk.emit(.byte(options.rawValue), line: expr.location.line)
	}

	public func visit(_ expr: DeclBlockSyntax, _ chunk: Chunk) throws {
		for decl in expr.decls {
			try decl.accept(self, chunk)
		}
	}

	public func visit(_ expr: TypeExprSyntax, _ chunk: Chunk) throws {
		if let symbol = try resolveStruct(named: typeOf(expr).symbol(in: symbols, source: .internal)) {
			chunk.emit(opcode: .getStruct, line: expr.location.line)
			chunk.emit(.symbol(symbol), line: expr.location.line)
		} else {
			throw CompilerError.unknownIdentifier("could not find struct named: \(expr.identifier.lexeme)")
		}
	}

	public func visit(_ expr: StructDeclSyntax, _ chunk: Chunk) throws {
		guard case let .instantiatable(.struct(type)) = try typeOf(expr) else {
			throw CompilerError.typeError("\(expr) not a struct")
		}

		let name = expr.name
		var structType = Struct(name: name, propertyCount: type.properties.count)

		for decl in expr.body.decls {
			switch decl {
			case let decl as InitDecl:
				// FIXME: we need to synthesize this
				if type.methods["init"] == nil {
					continue
				}

				guard case let .function(params, returns) = try typeOf(decl) else {
					throw CompilerError.typeError("\(decl) not a function")
				}

				let initSymbol = symbols.method(expr.name, "init", parameters: params.map(\.description), returns: returns.description, source: .internal)

				let declCompiler = ChunkCompiler(module: module, scopeDepth: scopeDepth + 1)
				let declChunk = Chunk(
					name: initSymbol.description,
					symbol: initSymbol,
					parent: chunk,
					arity: Byte(decl.params.count),
					depth: Byte(scopeDepth),
					path: chunk.path
				)

				// Define the actual params for this initializer
				for parameter in decl.params.params {
					_ = declCompiler.defineLocal(
						name: parameter.name,
						compiler: declCompiler,
						chunk: declChunk
					)
				}

				// Emit the init body
				for expr in decl.body.stmts {
					try expr.accept(declCompiler, declChunk)
				}

				// End the scope, which pops locals
				declCompiler.endScope(chunk: declChunk)

				// Make sure the instance is at the top of the stack and return it
				declChunk.emit(opcode: .getLocal, line: UInt32(decl.location.end.line))
				declChunk.emit(.symbol(.value(module.name, "self")), line: UInt32(decl.location.end.line))
				declChunk.emit(opcode: .returnValue, line: UInt32(decl.location.end.line))

				guard let methodType = type.methods["init"]?.asType(in: inferenceContext) else {
					throw CompilerError.typeError("No `init` found for \(expr.name)")
				}

				let methodSymbol = try methodType.symbol(in: symbols, name: "init", source: .internal)

				module.compiledChunks[methodSymbol] = declChunk
				structType.initializer = methodSymbol
			case let decl as FuncExprSyntax:
				guard let methodType = type.methods[decl.autoname]?.asType(in: inferenceContext),
							case let .function(params, returns) = methodType else {
					throw CompilerError.analysisError("Missing analyzer method for \(name).\(decl.autoname)")
				}

				let methodSymbol = symbols.method(expr.name, decl.autoname, parameters: params.map(\.description), returns: returns.description, source: .internal)

				try compile(type: name, method: decl, in: chunk, symbol: methodSymbol)
			case is VarDecl: ()
			case is LetDecl: ()
			default:
				throw CompilerError.typeError("Unknown decl: \(decl)")
			}
		}

		if type.methods["init"] == nil {
			let initSymbol = symbols.method(expr.name, "init", parameters: type.properties.values.map(\.description), returns: expr.name, source: .internal)
			structType.initializer = initSymbol
			let chunk = synthesizeInit(for: expr, inferenceType: type)
			module.compiledChunks[initSymbol] = chunk
		}

		module.structs[symbols.struct(expr.name, source: .internal)] = structType
	}

	public func visit(_: GenericParamsSyntax, _: Chunk) throws {
		// No need to emit any code here because generic params are just used by the analyzer... for now?
	}

	public func visit(_ expr: VarDeclSyntax, _ chunk: Chunk) throws {
		let type = try typeOf(expr)

		if false {
			// If it's at module scope, that means it's a global, which gets lazily initialized
			let variable = try emitLazyInitializer(for: expr, in: chunk)

			if let value = expr.value {
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

		if let value = expr.value {
			try value.accept(self, chunk)
			chunk.emit(opcode: .setLocal, line: value.location.line)
			chunk.emit(variable.code, line: value.location.line)
		}
	}

	public func visit(_ expr: LetDeclSyntax, _ chunk: Chunk) throws {
		if true {
			// If it's at module scope, that means it's a global, which gets lazily initialized
			let variable = try emitLazyInitializer(for: expr, in: chunk)

			if let value = expr.value {
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

		if let value = expr.value {
			try value.accept(self, chunk)
			chunk.emit(opcode: .setLocal, line: value.location.line)
			chunk.emit(variable.code, line: value.location.line)
		}
	}

	public func visit(_ expr: IfStmtSyntax, _ chunk: Chunk) throws {
		// Emit the condition
		try expr.condition.accept(self, chunk)

		// Emit the jumpUnless opcode, and keep track of where we are in the code.
		// We need this location so we can go back and patch the locations after emitting
		// the else stuff.
		let thenJumpLocation = chunk.emit(jump: .jumpUnless, line: expr.condition.location.line)

		// Pop the condition off the stack
		chunk.emit(opcode: .pop, line: expr.condition.location.line)

		// Emit the consequence block
		try expr.consequence.accept(self, chunk)

		// Emit the else jump, right after the consequence block. This is where we'll skip to
		// if the condition is false. If the condition was true, once the consequence block was
		// evaluated, we'll jump to past the alternative block.
		let elseJump = chunk.emit(jump: .jump, line: UInt32(expr.consequence.location.end.line))

		// Fill in the initial placeholder bytes now that we know how big the consequence block was
		try chunk.patchJump(thenJumpLocation)

		// Pop the condition off the stack
		chunk.emit(opcode: .pop, line: expr.condition.location.line)

		// Emit the alternative block
		if let alternative = expr.alternative {
			try alternative.accept(self, chunk)
		}

		// Fill in the else jump so we know how far to skip if the condition was true
		try chunk.patchJump(elseJump)
	}

	public func visit(_: StructExprSyntax, _: Chunk) throws {}

	public func visit(_ expr: SubscriptExprSyntax, _ chunk: Chunk) throws {
		// Emit the args
		for arg in expr.args {
			try arg.value.accept(self, chunk)
		}

		// Put the receiver at the top of the stack
		try expr.receiver.accept(self, chunk)
		chunk.emit(opcode: .get, line: expr.location.line)
	}

	public func visit(_: DictionaryLiteralExprSyntax, _: Chunk) throws {
		// Store the values
//		for element in expr.elements {
//			try visit(element, chunk)
//		}

//		let dictSlot = module.analysisModule.symbols[.struct("Standard", "Dictionary")]!.slot
//		chunk.emit(opcode: .getStruct, line: expr.location.line)
//		chunk.emit(byte: Byte(dictSlot), line: expr.location.line)
//		chunk.emit(opcode: .call, line: expr.location.line)

		// Emit the count so we can init enough storage
//		chunk.emit(byte: Byte(expr.elements.count), line: expr.location.line)
	}

	public func visit(_ expr: DictionaryElementExprSyntax, _ chunk: Chunk) throws {
		try expr.key.accept(self, chunk)
		try expr.value.accept(self, chunk)
	}

	public func visit(_: ProtocolDeclSyntax, _: Chunk) throws {
		// TODO: this
	}

	public func visit(_: ProtocolBodyDeclSyntax, _: Chunk) throws {
		// TODO: this
	}

	public func visit(_: FuncSignatureDeclSyntax, _: Chunk) throws {
		// TODO: this
	}

	public func visit(_ expr: EnumDeclSyntax, _ chunk: Chunk) throws {
		guard case let .instantiatable(.enumType(type)) = try typeOf(expr) else {
			throw CompilerError.typeError("\(expr) not an enum")
		}

		let enumType = Enum(
			name: expr.nameToken.lexeme,
			cases: type.cases.reduce(into: [:]) { res, kase in
				res[.property(module.name, type.name, kase.name)] = EnumCase(
					type: expr.nameToken.lexeme,
					name: kase.name,
					arity: kase.attachedTypes.count
				)
			}
		)

		for decl in expr.body.decls {
			guard let decl = decl as? FuncExprSyntax, case let .function(params, returns) = try typeOf(decl) else {
				continue
			}

			let symbol = symbols.method(expr.nameToken.lexeme, decl.autoname, parameters: params.map(\.description), returns: returns.description, source: .internal)
			try compile(type: expr.nameToken.lexeme, method: decl, in: chunk, symbol: symbol)
		}

		module.enums[symbols.enum(expr.nameToken.lexeme, source: .internal)] = enumType
	}

	public func visit(_ expr: EnumCaseDeclSyntax, _ chunk: Chunk) throws {
		chunk.emit(opcode: .getEnum, line: expr.location.line)
	}

	public func visit(_ expr: MatchStatementSyntax, _ chunk: Chunk) throws {
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
		for kase in expr.cases {
			try PatternCompiler(
				target: expr.target,
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
		for (i, kase) in expr.cases.enumerated() {
			try matchChunk.patchJump(caseJumps[i])

			try PatternCompiler(
				target: expr.target,
				caseStatement: kase,
				compiler: matchCompiler,
				chunk: matchChunk
			).compileBody()

			endJumps.append(
				matchChunk.emit(jump: .jump, line: kase.body.last?.location.line ?? kase.location.line)
			)
		}

		for jump in endJumps {
			try matchChunk.patchJump(jump)
		}

		matchChunk.emit(opcode: .endInline, line: expr.location.line)

		module.compiledChunks[matchSymbol] = matchChunk
	}

	public func visit(_: CaseStmtSyntax, _: Chunk) throws {
		// Handled by match stmt
	}

	public func visit(_ expr: EnumMemberExprSyntax, _ chunk: Chunk) throws {
		guard case let .enumCase(enumCase) = try typeOf(expr) else {
			throw CompilerError.unknownIdentifier("\(expr.description)")
		}

		chunk.emit(opcode: .getEnum, line: expr.location.line)
		chunk.emit(.symbol(.enum(module.name, enumCase.type.name)), line: expr.location.line)
		chunk.emit(.opcode(.getProperty), line: expr.location.line)
		chunk.emit(.symbol(.property(module.name, enumCase.type.name, enumCase.name)), line: expr.location.line)
		chunk.emit(.byte(0), line: expr.location.line) // Emit empty property options
	}

	public func visit(_ expr: InterpolatedStringExprSyntax, _ chunk: Chunk) throws {
		if expr.segments.isEmpty {
			return
		}

		// Emit the first segment so that the append call has two operands to concat
		var segments = expr.segments
		switch segments.removeFirst() {
		case let .string(string, _):
			chunk.emit(data: .init(kind: .string, bytes: [Byte](string.utf8)), line: expr.location.line)
		case let .expr(interpolation):
			try interpolation.expr.accept(self, chunk)
		}

		for segment in segments {
			switch segment {
			case let .string(string, _):
				chunk.emit(data: .init(kind: .string, bytes: [Byte](string.utf8)), line: expr.location.line)
			case let .expr(interpolation):
				try interpolation.expr.accept(self, chunk)
			}

			chunk.emit(.opcode(.appendInterpolation), line: expr.location.line)
		}
	}

	public func visit(_: ForStmtSyntax, _: Chunk) throws {
		#warning("Generated by Dev/generate-type.rb")
	}

	// GENERATOR_INSERTION

	// MARK: Helpers

	func compile(type: String, method decl: FuncExprSyntax, in chunk: Chunk, symbol: Symbol) throws {
		guard let declName = decl.name?.lexeme else {
			throw CompilerError.unknownIdentifier(decl.description)
		}

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
		for parameter in decl.params.params {
			_ = declCompiler.defineLocal(
				name: parameter.name,
				compiler: declCompiler,
				chunk: declChunk
			)
		}

		// Emit the body
		for expr in decl.body.stmts {
			try expr.accept(declCompiler, declChunk)
		}

		// End the scope, which pops locals
		declCompiler.endScope(chunk: declChunk)

		let opcode: Opcode = switch try typeOf(decl) {
		case .function(_, .void):
			.returnVoid
		default:
			.returnValue
		}

		declChunk.emit(opcode: opcode, line: UInt32(decl.location.end.line))

		module.compiledChunks[symbol] = declChunk
	}

	// Lookup the variable by name. If we've got it in our locals, just return the slot
	// for that variable. If we don't, search parent chunks to see if they've got it. If
	// they do, we've got an upvalue.
	public func resolveVariable(receiver: any Syntax, chunk: Chunk) throws -> Variable? {
		var varName: String?
		var symbol: Symbol?

		let type = try typeOf(receiver)

		if let syntax = receiver as? VarExpr {
			varName = syntax.name
			symbol = try type.symbol(in: symbols, source: .internal)
		} else if let syntax = receiver as? any VarLetDecl {
			varName = syntax.name
			symbol = try type.symbol(in: symbols, source: .internal)
		}

		if let varName, let variable = try resolveVariable(named: varName, symbol: symbol, chunk: chunk) {
			return variable
		}

		if let syntax = receiver as? MemberExpr	{
			return Variable(
				name: syntax.property,
				code: .symbol(symbols.property(syntax.receiver?.description, syntax.property, source: .internal)),
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

	private func emitLazyInitializer(for expr: any VarLetDecl, in chunk: Chunk) throws -> Variable {
		// If this is a global module value, we want to evaluate it lazily. This is nice because
		// it doesn't incur startup overhead as well as lets us not worry so much about the order
		// in which files are evaluated.
		//
		// We save a lil chunk that initializes the value along with the module that can get called
		// when the global is referenced to set the initial value.
		guard let variable = try resolveVariable(receiver: expr, chunk: chunk) else {
			throw CompilerError.unknownIdentifier(expr.nameToken.lexeme)
		}

		let symbol = symbols.value(variable.name, source: .internal)

		let initializerChunk = Chunk(name: "$initialize_\(variable.name)", symbol: symbol, path: chunk.path)
		let initializerCompiler = ChunkCompiler(module: module)

		// Emit actual value initialization into the chunk
		try expr.value?.accept(initializerCompiler, initializerChunk)

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

	private func synthesizeInit(for decl: StructDeclSyntax, inferenceType type: StructType) -> Chunk {
		let symbol = symbols.method(decl.name, "init", parameters: type.properties.values.map(\.description), returns: "self", source: .internal)
		let chunk = Chunk(
			name: symbol.description,
			symbol: symbol,
			parent: nil,
			arity: Byte(type.properties.count),
			depth: Byte(scopeDepth),
			path: "<init>"
		)

		let compiler = ChunkCompiler(module: module)

		// Define the params for this function
		var variables: [(Variable, InferenceResult)] = []
		for (name, property) in type.properties {
			let variable = compiler.defineLocal(
				name: name,
				compiler: compiler,
				chunk: chunk
			)

			variables.append((variable, property))
		}

		for (variable, property) in variables {
			// Put the parameter value onto the stack
			chunk.emit(opcode: .getLocal, line: 9999)
			chunk.emit(variable.code, line: 9999)

			// Get self
			chunk.emit(opcode: .getLocal, line: 9999)
			chunk.emit(.symbol(.value(module.name, "self")), line: 9999)

			// Set the property on self
			let propertySymbol = symbols.property(decl.name, variable.name, source: .internal)
			chunk.emit(opcode: .setProperty, line: 9999)
			chunk.emit(.symbol(propertySymbol), line: 9999)
		}

		compiler.endScope(chunk: chunk)

		// Put `self` back on the stack so we always return this new instance
		chunk.emit(opcode: .getLocal, line: 9999)
		chunk.emit(.symbol(.value(module.name, "self")), line: 9999)
		chunk.emit(opcode: .returnValue, line: 9999)

		return chunk
	}
}
