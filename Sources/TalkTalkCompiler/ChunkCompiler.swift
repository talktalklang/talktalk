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

	// Tracks which locals have been captured
//	public var captures: [String] = []

	// Track which locals have been created in this scope
	public var localsCount = 1

	public var upvalues: [(ancestorDepth: Byte, ancestorSlot: Byte)] = []

	public init(module: CompilingModule, scopeDepth: Int = 0, parent: ChunkCompiler? = nil) {
		self.module = module
		self.scopeDepth = scopeDepth
		self.parent = parent
		self.locals = [.reserved(depth: scopeDepth)]
	}

	public func endScope(chunk: Chunk) {
		for i in 0 ..< locals.count {
			let local = locals[i]
			if local.isCaptured {
				chunk.emit(opcode: .captureUpvalue, line: chunk.lines.last!)
				chunk.emit(byte: Byte(i), line: chunk.lines.last!)
			}
		}
	}

	// MARK: Visitor methods

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
			chunk.emit(opcode: .pop, line: expr.location.line)
		case .return:
			// If this is the only statement in a block, we can sometimes implicitly return
			// its expr instead of just popping it (like in a function body). We don't want to
			// do this for things like if/while statements tho.
			chunk.emit(opcode: .return, line: expr.location.line)
		case .none:
			() // Leave the value on the stack
		}
	}

	public func visit(_: AnalyzedImportStmt, _: Chunk) throws {
		// This is just an analysis thing
	}

	public func visit(_ expr: AnalyzedCallExpr, _ chunk: Chunk) throws {
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

		let variable = resolveVariable(
			receiver: expr.receiverAnalyzed,
			chunk: chunk
		)

		guard let variable else {
			throw CompilerError.unknownIdentifier(
				expr.description + " at line: \(expr.location.start.line)"
			)
		}

		// If this is a member, we need to put the member's owner on the stack as well
		if let member = expr.receiverAnalyzed as? AnalyzedMemberExpr {
			try member.receiverAnalyzed.accept(self, chunk)
		}

		chunk.emit(opcode: variable.setter, line: expr.location.line)
		chunk.emit(byte: variable.slot, line: expr.location.line)

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
			fatalError("unreachable")
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
			let variable = resolveVariable(
				receiver: expr,
				chunk: chunk
			)
		else {
			throw CompilerError.unknownIdentifier(expr.name + " at line: \(expr.location.start.line)")
		}

		chunk.emit(opcode: variable.getter, line: expr.location.line)
		chunk.emit(byte: variable.slot, line: expr.location.line)
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

	public func visit(_ expr: AnalyzedInitDecl, _ initChunk: Chunk) throws {
		guard let structType = expr.environment.getLexicalScope()?.scope, let structName = structType.name else {
			fatalError("no name for struct for init")
		}

		let symbol: Symbol = .method(structName, "init", expr.parameters.params.map(\.name))
		let initCompiler = ChunkCompiler(module: module, scopeDepth: scopeDepth + 1, parent: self)

		// Define the actual params for this initializer
//		for parameter in expr.parametersAnalyzed.paramsAnalyzed {
//			_ = initCompiler.defineLocal(name: parameter.name, compiler: initCompiler, chunk: initChunk)
//		}

		// Define the params for this function
		for parameter in expr.parametersAnalyzed.paramsAnalyzed {
			let variable = defineLocal(name: parameter.name, compiler: initCompiler, chunk: initChunk)

//			initChunk.emit(opcode: .setLocal, line: parameter.location.line)
//			initChunk.emit(byte: Byte(variable.slot), line: parameter.location.line)
		}

		// Emit the init body
		try initCompiler.visit(expr.bodyAnalyzed, initChunk)

		// End the scope, which pops locals
		initCompiler.endScope(chunk: initChunk)

		// We always want to emit return the instance at the end of init
		initChunk.emit(opcode: .getLocal, line: UInt32(expr.location.end.line))
		initChunk.emit(byte: 0, line: UInt32(expr.location.end.line))
		initChunk.emit(opcode: .return, line: UInt32(expr.location.end.line))

		// Save the chunk into the struct's methods
		module.structMethods[.struct(structName), default: [:]][symbol] = initChunk
	}

	public func visit(_ expr: AnalyzedFuncExpr, _ chunk: Chunk) throws {
		let functionChunk = Chunk(
			name: expr.name?.lexeme ?? expr.autoname, parent: chunk,
			arity: Byte(expr.analyzedParams.params.count), depth: Byte(scopeDepth)
		)
		let functionCompiler = ChunkCompiler(module: module, scopeDepth: scopeDepth + 1, parent: self)
		let subchunkID = chunk.addChunk(functionChunk)
		var localSlot: Byte = 0

		// Define the params for this function
		for parameter in expr.analyzedParams.paramsAnalyzed {
			_ = defineLocal(name: parameter.name, compiler: functionCompiler, chunk: functionChunk)

//			functionChunk.emit(opcode: .setLocal, line: parameter.location.line)
//			functionChunk.emit(byte: Byte(variable.slot), line: parameter.location.line)
		}

		if let name = expr.name?.lexeme {
			let variable = defineLocal(name: name, compiler: self, chunk: chunk)
			localSlot = variable.slot
		}

		if let name = expr.name {
			// Define the function inside its body for recursion
//			let variable = functionCompiler.defineLocal(name: name.lexeme, compiler: functionCompiler, chunk: functionChunk)
//			let upvalue = functionCompiler.addUpvalue(localSlot, depth: 1, name: name.lexeme, chunk: functionChunk, owner: self)
//			let slot = functionCompiler.resolveUpvalue(named: name.lexeme, chunk: functionChunk)
//			functionChunk.emitClosure(subchunkID: Byte(subchunkID), localSlot: variable.slot, line: expr.location.line)
		}

		// Emit the function body
		try functionCompiler.visit(expr.bodyAnalyzed, functionChunk)

		// End the scope, which pops or captures locals
		functionCompiler.endScope(chunk: functionChunk)

		// We always want to emit a return at the end of a function
		functionChunk.emit(opcode: .return, line: UInt32(expr.location.end.line))

		// Store the upvalues count
		functionChunk.upvalueCount = Byte(functionCompiler.upvalues.count)

		let line = UInt32(expr.location.line)
		chunk.emitClosure(subchunkID: Byte(subchunkID), localSlot: localSlot, line: line)

		for upvalue in functionCompiler.upvalues {
			chunk.emit(byte: upvalue.ancestorDepth, line: line)
			chunk.emit(byte: upvalue.ancestorSlot, line: line)
		}
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

	public func visit(_: AnalyzedParamsExpr, _: Chunk) throws {
		fatalError("TODO")
	}

	public func visit(_: AnalyzedParam, _: Chunk) throws {
		fatalError("TODO")
	}

	public func visit(_ expr: AnalyzedReturnStmt, _ chunk: Chunk) throws {
		try expr.valueAnalyzed?.accept(self, chunk)
		chunk.emit(opcode: .return, line: expr.location.line)
	}

	public func visit(_ expr: AnalyzedMemberExpr, _ chunk: Chunk) throws {
		try expr.receiverAnalyzed.accept(self, chunk)

		// Emit the getter
		chunk.emit(opcode: .getProperty, line: expr.location.line)

		// Emit the property's slot
		let slot = expr.memberAnalyzed.slot
		chunk.emit(byte: Byte(slot), line: expr.location.line)

		// Emit the property's optionset
		var options = PropertyOptions()
		if expr.memberAnalyzed is Method {
			options.insert(.isMethod)
		}
		chunk.emit(byte: options.rawValue, line: expr.location.line)
	}

	public func visit(_ expr: AnalyzedDeclBlock, _ chunk: Chunk) throws {
		for decl in expr.declsAnalyzed {
			try decl.accept(self, chunk)
		}
	}

	public func visit(_ expr: AnalyzedTypeExpr, _ chunk: Chunk) throws {
		if let slot = resolveStruct(named: expr.identifier.lexeme) {
			chunk.emit(opcode: .getStruct, line: expr.location.line)
			chunk.emit(byte: slot, line: expr.location.line)
		} else {
			let type = expr.environment.type(named: expr.identifier.lexeme)
			if let primitive = type.primitive {
				chunk.emit(opcode: .primitive, line: expr.location.line)
				chunk.emit(byte: primitive.rawValue, line: expr.location.line)
			} else {
				throw CompilerError.unknownIdentifier("could not find struct named: \(expr.identifier.lexeme)")
			}
		}
	}

	public func visit(_ expr: AnalyzedStructDecl, _ chunk: Chunk) throws {
		let name = expr.name
		var structType = Struct(name: name, propertyCount: expr.structType.properties.count)
		var methods: [Chunk?] = Array(repeating: nil, count: expr.structType.methods.count)

		// Go through the body and collect the chunks (we don't want to emit them into the
		// outer chunk)
		for decl in expr.bodyAnalyzed.declsAnalyzed {
			switch decl {
			case let decl as AnalyzedInitDecl:
				if expr.structType.methods["init"]?.isSynthetic == true {
					continue
				}

//				let symbol = Symbol.initializer(name, decl.parameters.params.map(\.name))
//				let declCompiler = ChunkCompiler(module: module, scopeDepth: scopeDepth + 1)
//				let declChunk = Chunk(
//					name: symbol.description, parent: chunk, arity: Byte(decl.parameters.count),
//					depth: Byte(scopeDepth)
//				)
//
//				// Define the actual params for this initializer
//				for parameter in decl.parametersAnalyzed.paramsAnalyzed {
//					_ = declCompiler.defineLocal(
//						name: parameter.name, compiler: declCompiler, chunk: declChunk
//					)
//				}
//
//				// Emit the init body
//				for expr in decl.bodyAnalyzed.declsAnalyzed {
//					try expr.accept(declCompiler, declChunk)
//				}
//
//				// End the scope, which pops locals
//				declCompiler.endScope(chunk: declChunk)

				// Make sure the instance is at the top of the stack and return it
//				declChunk.emit(opcode: .getLocal, line: UInt32(decl.location.end.line))
//				declChunk.emit(byte: 0, line: UInt32(decl.location.end.line))
//				declChunk.emit(opcode: .return, line: UInt32(decl.location.end.line))

				let symbol = Symbol.initializer(name, decl.parameters.params.map(\.name))
				let initCompiler = ChunkCompiler(module: module, scopeDepth: scopeDepth + 1)
				let initChunk = Chunk(
					name: symbol.description,
					parent: chunk,
					arity: Byte(decl.parameters.count),
					depth: Byte(scopeDepth)
				)

				try initCompiler.visit(decl, initChunk)
				let analysisMethod = expr.structType.methods["init"]!
				methods[analysisMethod.slot] = initChunk
			case let decl as AnalyzedFuncExpr:
				let symbol = Symbol.method(name, decl.name!.lexeme, decl.params.params.map(\.name))
				let declCompiler = ChunkCompiler(module: module, scopeDepth: scopeDepth + 1)
				let declChunk = Chunk(
					name: symbol.description, parent: chunk, arity: Byte(decl.params.count),
					depth: Byte(scopeDepth)
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
				declChunk.emit(opcode: .return, line: UInt32(decl.location.end.line))

				let analysisMethod = expr.structType.methods[decl.name!.lexeme]!
				methods[analysisMethod.slot] = declChunk
			case is AnalyzedVarDecl: ()
			case is AnalyzedLetDecl: ()
			default:
				fatalError("unknown decl: \(decl)")
			}
		}

		let initializer = expr.structType.methods["init"]!

		if initializer.isSynthetic {
			methods[initializer.slot] = synthesizeInit(for: expr.structType)
		}

		structType.initializer = initializer.slot

		structType.methods = methods.map { $0! }
		module.structs[.struct(name)] = structType
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
				chunk.emit(byte: variable.slot, line: value.location.line)
			}

			return
		}

		let variable = defineLocal(name: expr.name, compiler: self, chunk: chunk)
		if let value = expr.valueAnalyzed {
			try value.accept(self, chunk)
			chunk.emit(opcode: .setLocal, line: value.location.line)
			chunk.emit(byte: variable.slot, line: value.location.line)
		}
	}

	public func visit(_ expr: AnalyzedLetDecl, _ chunk: Chunk) throws {
		if expr.environment.isModuleScope {
			// If it's at module scope, that means it's a global, which gets lazily initialized
			let variable = try emitLazyInitializer(for: expr, in: chunk)

			if let value = expr.valueAnalyzed {
				try value.accept(self, chunk)
				chunk.emit(opcode: .setModuleValue, line: value.location.line)
				chunk.emit(byte: variable.slot, line: value.location.line)
			}

			return
		}

		let variable = defineLocal(name: expr.name, compiler: self, chunk: chunk)
		if let value = expr.valueAnalyzed {
			try value.accept(self, chunk)
			chunk.emit(opcode: .setLocal, line: value.location.line)
			chunk.emit(byte: variable.slot, line: value.location.line)
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

		// Pop the condition off the stack (TODO: why again?)
//		chunk.emit(opcode: .pop, line: expr.conditionAnalyzed.location.line)

		// Emit the alternative block
		if let alternativeAnalyzed = expr.alternativeAnalyzed {
			try alternativeAnalyzed.accept(self, chunk)
		}

		// Fill in the else jump so we know how far to skip if the condition was true
		try chunk.patchJump(elseJump)
	}

	public func visit(_: AnalyzedStructExpr, _: Chunk) throws {
		fatalError("TODO")
	}

	// GENERATOR_INSERTION

	// MARK: Helpers

	// Lookup the variable by name. If we've got it in our locals, just return the slot
	// for that variable. If we don't, search parent chunks to see if they've got it. If
	// they do, we've got an upvalue.
	public func resolveVariable(receiver: any AnalyzedSyntax, chunk: Chunk) -> Variable? {
		var varName: String?

		if let syntax = receiver as? any VarExpr {
			varName = syntax.name
		} else if let syntax = receiver as? VarLetDecl {
			varName = syntax.name
		}

		if let varName {
			if varName == "self" {
				return Variable(
					name: varName,
					slot: 0,
					depth: scopeDepth,
					isCaptured: false,
					getter: .getLocal,
					setter: .setLocal
				)
			}

			if let slot = resolveLocal(named: varName) {
				return Variable(
					name: varName,
					slot: slot,
					depth: scopeDepth,
					isCaptured: false,
					getter: .getLocal,
					setter: .setLocal
				)
			}

			if let slot = resolveUpvalue(named: varName, chunk: chunk) {
				return Variable(
					name: varName,
					slot: slot,
					depth: scopeDepth,
					isCaptured: false,
					getter: .getUpvalue,
					setter: .setUpvalue
				)
			}

			if let slot = resolveModuleFunction(named: varName) {
				return Variable(
					name: varName,
					slot: slot,
					depth: scopeDepth,
					isCaptured: false,
					getter: .getModuleFunction,
					setter: .setModuleFunction
				)
			}

			if let slot = resolveModuleValue(named: varName) {
				return Variable(
					name: varName,
					slot: slot,
					depth: scopeDepth,
					isCaptured: false,
					getter: .getModuleValue,
					setter: .setModuleValue
				)
			}

			if let slot = resolveStruct(named: varName) {
				return Variable(
					name: varName,
					slot: slot,
					depth: scopeDepth,
					isCaptured: false,
					getter: .getStruct,
					setter: .setStruct
				)
			}

			if let builtinStruct = BuiltinStruct.lookup(name: varName) {
				return Variable(
					name: builtinStruct.name,
					slot: builtinStruct.slot(),
					depth: scopeDepth,
					isCaptured: false,
					getter: .getBuiltinStruct,
					setter: .setBuiltinStruct
				)
			}

			if let slot = BuiltinFunction.list.firstIndex(where: { $0.name == varName }) {
				return Variable(
					name: varName,
					slot: Byte(slot),
					depth: scopeDepth,
					isCaptured: false,
					getter: .getBuiltin,
					setter: .setBuiltin
				)
			}
		}

		if let syntax = receiver as? AnalyzedMemberExpr {
			return Variable(
				name: syntax.property,
				slot: Byte(syntax.memberAnalyzed.slot),
				depth: scopeDepth,
				isCaptured: false,
				getter: .getProperty,
				setter: .setProperty
			)
		}

		return nil
	}

	// Just look up the var in our locals
	public func resolveLocal(named name: String) -> Byte? {
		if let variable = locals.first(where: { $0.name == name }) {
			return variable.slot
		}

		return nil
	}

	// Search parent chunks for the variable
	private func resolveUpvalue(named name: String, chunk: Chunk) -> Byte? {
		// How far should we reach back in the call frame stack to find this variable
		var depth: Byte = 1
		var parent = parent

		while let nextParent = parent {
			if let local = nextParent.resolveLocal(named: name) {
				return addUpvalue(local, depth: depth, name: name, chunk: chunk, owner: nextParent)
			}

			parent = nextParent.parent
			depth += 1
		}

		return nil
	}

	// Check the CompilingModule for a global function.
	private func resolveModuleFunction(named name: String) -> Byte? {
		if let offset = module.moduleFunctionOffset(for: name) {
			return Byte(offset)
		}

		return nil
	}

	// Check CompilingModule for a global value
	private func resolveModuleValue(named name: String) -> Byte? {
		if let offset = module.moduleValueOffset(for: name) {
			return Byte(offset)
		}

		return nil
	}

	// Check CompilationModule for a global struct
	private func resolveStruct(named name: String) -> Byte? {
		if let offset = module.symbols[.struct(name)] {
			return Byte(offset)
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
		guard let variable = resolveVariable(receiver: expr, chunk: chunk) else {
			throw CompilerError.unknownIdentifier(expr.nameToken.lexeme)
		}

		let initializerChunk = Chunk(name: "$initialize_\(variable.name)")
		let initializerCompiler = ChunkCompiler(module: module)

		// Emit actual value initialization into the chunk
		try expr.valueAnalyzed?.accept(initializerCompiler, initializerChunk)

		// Set the module value so it can be used going forward
		initializerChunk.emit(opcode: .setModuleValue, line: expr.location.line)
		initializerChunk.emit(byte: variable.slot, line: expr.location.line)

		// Return the actual value
		initializerChunk.emit(opcode: .getModuleValue, line: expr.location.line)
		initializerChunk.emit(byte: variable.slot, line: expr.location.line)

		// Return from the initialization chunk
		initializerChunk.emit(opcode: .return, line: expr.location.line)

		module.valueInitializers[.value(variable.name)] = initializerChunk

		return variable
	}

	private func defineLocal(
		name: String,
		compiler: ChunkCompiler,
		chunk: Chunk
	) -> Variable {
		let variable = Variable(
			name: name,
			slot: Byte(compiler.locals.count),
			depth: compiler.scopeDepth,
			isCaptured: false,
			getter: .getLocal,
			setter: .setLocal
		)

		chunk.localsCount += 1
		chunk.localNames.append(name)
		compiler.locals.append(variable)

		return variable
	}

	private func addUpvalue(_ slot: Byte, depth: Byte, name: String, chunk: Chunk, owner: ChunkCompiler) -> Byte {
		for (i, upvalue) in upvalues.enumerated() {
			// Check to see if we already have this upvalue. If so, just return the one we have
			if upvalue.ancestorDepth == depth, upvalue.ancestorSlot == slot {
				return Byte(i)
			}
		}

		// Otherwise add it
		upvalues.append((ancestorDepth: depth, ancestorSlot: slot))
		chunk.upvalueNames.append(name)

		// Tell the scope that owns the local that this variable is captured now
		owner.locals[Int(slot)].isCaptured = true

		return Byte(upvalues.count - 1)
	}

	private func synthesizeInit(for structType: StructType) -> Chunk {
		let params = Array(structType.properties.keys)
		let chunk = Chunk(
			name: Symbol.initializer(structType.name!, params).description,
			parent: nil,
			arity: Byte(params.count),
			depth: Byte(scopeDepth)
		)

		let compiler = ChunkCompiler(module: module)

		// Define the params for this function
		var variables: [(Variable, Property)] = []
		for (name, property) in structType.properties {
			let variable = compiler.defineLocal(
				name: name,
				compiler: compiler,
				chunk: chunk
			)

			variables.append((variable, property))

			// Get the value to set the property as
			chunk.emit(opcode: .getLocal, line: 9999)
			chunk.emit(byte: variable.slot, line: 9999)

			// Get self
			chunk.emit(opcode: .getLocal, line: 9999)
			chunk.emit(byte: 0, line: 9999)

			// Set the property on self
			chunk.emit(opcode: .setProperty, line: 9999)
			chunk.emit(byte: Byte(property.slot), line: 9999)

			// Pop self off the stack
			chunk.emit(opcode: .pop, line: 9999)
		}

		// Put the instance on top of the stack to get popped
		chunk.emit(opcode: .getLocal, line: 9999)
		chunk.emit(byte: 0, line: 9999)

		compiler.endScope(chunk: chunk)
		chunk.emit(opcode: .return, line: 9999)

		return chunk
	}
}
