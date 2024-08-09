//
//  CompilerVisitor.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/2/24.
//

import TalkTalkAnalysis
import TalkTalkBytecode

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
	public var captures: [String] = []

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

	public func visit(_ expr: AnalyzedIdentifierExpr, _ context: Chunk) throws {}

	public func visit(_ expr: AnalyzedImportStmt, _ context: Chunk) throws {}

	public func visit(_ expr: AnalyzedCallExpr, _ chunk: Chunk) throws {
		// Put the function args on the stack
		for arg in expr.argsAnalyzed {
			try arg.expr.accept(self, chunk)
		}

		// Put the callee on the stack
		try expr.calleeAnalyzed.accept(self, chunk)

		// Call the callee
		chunk.emit(opcode: .call, line: expr.location.line)
	}

	public func visit(_ expr: AnalyzedDefExpr, _ chunk: Chunk) throws {
		// Put the value onto the stack
		try expr.valueAnalyzed.accept(self, chunk)

		let variable = resolveVariable(
			named: expr.name.lexeme,
			chunk: chunk
		) ?? defineLocal(name: expr.name.lexeme, compiler: self, chunk: chunk)

		chunk.emit(opcode: variable.setter, line: expr.location.line)
		chunk.emit(byte: variable.slot, line: expr.location.line)

		// If this is a global module value, we want to evaluate it lazily. This is nice because
		// it doesn't incur startup overhead as well as lets us not worry so much about the order
		// in which files are evaluated.
		//
		// We save a lil chunk that initializes the value along with the module that can get called
		// when the global is referenced to set the initial value.
		if variable.setter == .setModuleValue {
			let initializerChunk = Chunk(name: "$init_\(variable.name)")
			let initializerCompiler = ChunkCompiler(module: module)

			// Emit actual value initialization into the chunk
			try expr.valueAnalyzed.accept(initializerCompiler, initializerChunk)

			// Set the module value so it can be used going forward
			initializerChunk.emit(opcode: .setModuleValue, line: expr.location.line)
			initializerChunk.emit(byte: variable.slot, line: expr.location.line)

			// Return the actual value
			initializerChunk.emit(opcode: .getModuleValue, line: expr.location.line)
			initializerChunk.emit(byte: variable.slot, line: expr.location.line)

			// Return from the initialization chunk
			initializerChunk.emit(opcode: .return, line: expr.location.line)

			module.valueInitializers[.value(variable.name)] = initializerChunk
		}

		if variable.setter == .setUpvalue {
			chunk.emit(opcode: .pop, line: expr.location.line)
		}
	}

	public func visit(_ expr: AnalyzedErrorSyntax, _ chunk: Chunk) throws {
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
		case .int(let int):
			chunk.emit(constant: .int(Int64(int)), line: expr.location.line)
		case .bool(let bool):
			chunk.emit(opcode: bool ? .true : .false, line: expr.location.line)
		case .string(let string):
			var string = string.utf8CString
			string.withUnsafeMutableBufferPointer {
				chunk.emit(data: Object.string($0).bytes, line: expr.location.line)
			}
		case .none:
			chunk.emit(opcode: .none, line: expr.location.line)
		}
	}

	public func visit(_ expr: AnalyzedVarExpr, _ chunk: Chunk) throws {
		guard let variable = resolveVariable(
			named: expr.name,
			chunk: chunk
		) else {
			throw CompilerError.unknownIdentifier(expr.name)
		}

		chunk.emit(opcode: variable.getter, line: expr.location.line)
		chunk.emit(byte: variable.slot, line: expr.location.line)
	}

	public func visit(_ expr: AnalyzedBinaryExpr, _ chunk: Chunk) throws {
		let opcode: Opcode = switch expr.op {
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
		}

		try expr.rhsAnalyzed.accept(self, chunk)
		try expr.lhsAnalyzed.accept(self, chunk)

		chunk.emit(opcode: opcode, line: expr.location.line)
	}

	public func visit(_ expr: AnalyzedIfExpr, _ chunk: Chunk) throws {
		// Emit the condition
		try expr.conditionAnalyzed.accept(self, chunk)

		// Emit the jumpUnless opcode, and keep track of where we are in the code. We need this location
		// so we can go back and patch the locations after emitting the else stuff.
		let thenJumpLocation = chunk.emit(jump: .jumpUnless, line: expr.condition.location.line)

		// Pop the condition off the stack
		chunk.emit(opcode: .pop, line: expr.condition.location.line)

		// Emit the consequence block
		try expr.consequenceAnalyzed.accept(self, chunk)

		// Emit the else jump, right after the consequence block. This is where we'll skip to if the condition
		// is false. If the condition was true, once the consequence block was evaluated, we'll jump to past
		// the alternative block.
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

	public func visit(_ expr: AnalyzedInitDecl, _ context: Chunk) throws -> Void {
		fatalError("TODO")
	}

	public func visit(_ expr: AnalyzedFuncExpr, _ chunk: Chunk) throws {
		let functionChunk = Chunk(name: expr.name?.lexeme ?? expr.autoname, parent: chunk, arity: Byte(expr.analyzedParams.params.count), depth: Byte(scopeDepth))
		let functionCompiler = ChunkCompiler(module: module, scopeDepth: scopeDepth + 1, parent: self)

		if let name = expr.name {
			_ = defineLocal(name: name.lexeme, compiler: self, chunk: chunk)
		}

		// Define the params for this function
		for (i, parameter) in expr.analyzedParams.paramsAnalyzed.enumerated() {
			_ = defineLocal(name: parameter.name, compiler: functionCompiler, chunk: chunk)

			functionChunk.emit(opcode: .setLocal, line: parameter.location.line)
			functionChunk.emit(byte: Byte(i), line: parameter.location.line)
		}

		// Emit the function body
		for expr in expr.bodyAnalyzed.exprsAnalyzed {
			try expr.accept(functionCompiler, functionChunk)
		}

		// End the scope, which pops or captures locals
		functionCompiler.endScope(chunk: functionChunk)

		// We always want to emit a return at the end of a function
		functionChunk.emit(opcode: .return, line: UInt32(expr.location.end.line))

		// Store the upvalues count
		functionChunk.upvalueCount = Byte(functionCompiler.upvalues.count)

//		let subchunkID = Byte(chunk.subchunks.count)
//		chunk.subchunks.append(functionChunk)
		let line = UInt32(expr.location.line)
		let subchunkID = chunk.addChunk(functionChunk)
		chunk.emitClosure(subchunkID: Byte(subchunkID), line: line)

		for upvalue in functionCompiler.upvalues {
			chunk.emit(byte: upvalue.isLocal ? 1 : 0, line: line)
			chunk.emit(byte: upvalue.index, line: line)
		}
	}

	public func visit(_ expr: AnalyzedBlockExpr, _ chunk: Chunk) throws {
		for expr in expr.exprsAnalyzed {
			try expr.accept(self, chunk)
		}
	}

	public func visit(_ expr: AnalyzedWhileExpr, _ chunk: Chunk) throws {}

	public func visit(_ expr: AnalyzedParamsExpr, _ chunk: Chunk) throws {}

	public func visit(_ expr: AnalyzedReturnExpr, _ chunk: Chunk) throws {}

	public func visit(_ expr: AnalyzedMemberExpr, _ chunk: Chunk) throws {
		// Put the receiver on the stack
		try expr.receiverAnalyzed.accept(self, chunk)

		// Emit the getter
		chunk.emit(opcode: .getProperty, line: expr.location.line)
		chunk.emit(byte: Byte(expr.propertyAnalyzed.slot), line: expr.location.line)
	}

	public func visit(_ expr: AnalyzedDeclBlock, _ chunk: Chunk) throws {}

	public func visit(_ expr: AnalyzedStructExpr, _ chunk: Chunk) throws {
		let name = expr.name ?? "<struct\(module.structs.count)>"
		module.structs[.struct(name)] = Struct(name: name, propertyCount: expr.structType.properties.count)
	}

	public func visit(_ expr: AnalyzedVarDecl, _ chunk: Chunk) throws {}

	public func visit(_ expr: AnalyzedLetDecl, _ chunk: Chunk) throws {}

	// MARK: Helpers

	// Lookup the variable by name. If we've got it in our locals, just return the slot
	// for that variable. If we don't, search parent chunks to see if they've got it. If
	// they do, we've got an upvalue.
	public func resolveVariable(named name: String, chunk: Chunk) -> Variable? {
		if let slot = resolveLocal(named: name) {
			return Variable(
				name: name,
				slot: slot,
				depth: scopeDepth,
				isCaptured: false,
				getter: .getLocal,
				setter: .setLocal
			)
		}

		if let slot = resolveUpvalue(named: name, chunk: chunk) {
			return Variable(
				name: name,
				slot: slot,
				depth: scopeDepth,
				isCaptured: false,
				getter: .getUpvalue,
				setter: .setUpvalue
			)
		}

		if let slot = resolveModuleFunction(named: name) {
			return Variable(
				name: name,
				slot: slot,
				depth: scopeDepth,
				isCaptured: false,
				getter: .getModuleFunction,
				setter: .setModuleFunction
			)
		}

		if let slot = resolveModuleValue(named: name) {
			return Variable(
				name: name,
				slot: slot,
				depth: scopeDepth,
				isCaptured: false,
				getter: .getModuleValue,
				setter: .setModuleValue
			)
		}

		if let slot = resolveStruct(named: name) {
			return Variable(
				name: name,
				slot: slot,
				depth: scopeDepth,
				isCaptured: false,
				getter: .getStruct,
				setter: .setStruct
			)
		}

		if let slot = Builtin.list.firstIndex(where: { $0.name == name }) {
			return Variable(
				name: name,
				slot: Byte(slot),
				depth: scopeDepth,
				isCaptured: false,
				getter: .getBuiltin,
				setter: .setBuiltin
			)
		}

		return nil
	}

	// Just look up the var in our locals
	public func resolveLocal(named name: String) -> Byte? {
		if let i = locals.firstIndex(where: { $0.name == name }) {
			return Byte(i)
		}

		return nil
	}

	// Search parent chunks for the variable
	private func resolveUpvalue(named name: String, chunk: Chunk) -> Byte? {
		guard let parent else { return nil }

		// If our immediate parent has the variable, we return an upvalue.
		if let local = parent.resolveLocal(named: name) {
			// Since it's in the immediate parent, we mark the upvalue as captured.
			parent.captures.append(name)
			return addUpvalue(local, isLocal: true, name: name, chunk: chunk)
		}

		// Check for upvalues in the parent. We don't need to mark the upvalue where it's found
		// as captured since the immediate child of the owning scope will handle that in its
		// resolveUpvalue call.
		if let local = parent.resolveUpvalue(named: name, chunk: chunk) {
			return addUpvalue(local, isLocal: false, name: name, chunk: chunk)
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

	private func addUpvalue(_ index: Byte, isLocal: Bool, name: String, chunk: Chunk) -> Byte {
		// If we've already got it, return it
		for (i, upvalue) in upvalues.enumerated() {
			if upvalue.index == index, upvalue.isLocal {
				return Byte(i)
			}
		}

		// Otherwise add a new one
		upvalues.append((index: index, isLocal: isLocal))
		chunk.upvalueNames.append(name)

		return Byte(upvalues.count - 1)
	}
}
