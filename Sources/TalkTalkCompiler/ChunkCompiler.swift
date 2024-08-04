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

	// If this is a subchunk it has a parent compiler. We use this to resolve upvalues
	public var parent: ChunkCompiler?

	// Tracks local variable slots
	public var localsTable: [String: Byte] = [:]

	// Tracks which locals have been captured
	public var captures: [String] = []

	// Track which locals have been created in this scope
	public var localsCount = 0

	// Tracks how many upvalues we currently have
	public var upvalues: [(index: Byte, isLocal: Bool)] = []

	public init(scopeDepth: Int = 0, parent: ChunkCompiler? = nil) {
		self.scopeDepth = scopeDepth
		self.parent = parent
	}

	public func endScope(chunk: Chunk) {
		for (_, _) in localsTable {
			chunk.emit(opcode: .pop, line: 0)
		}
	}

	// MARK: Visitor methods

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

		let name = expr.name.lexeme
		let local = localsTable[name, default: Byte(localsTable.count)]
		localsTable[name] = local
		localsCount++

		chunk.emit(opcode: .setLocal, line: expr.location.line)
		chunk.emit(byte: local, line: expr.location.line)
	}

	public func visit(_ expr: AnalyzedErrorSyntax, _ chunk: Chunk) throws {
		fatalError("unreachable")
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
		guard let (opcode, slot) = resolveVariable(named: expr.name) else {
			throw CompilerError.unknownLocal(expr.name)
		}

		chunk.emit(opcode: opcode, line: expr.location.line)
		chunk.emit(byte: slot, line: expr.location.line)
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

	public func visit(_ expr: AnalyzedFuncExpr, _ chunk: Chunk) throws {
		let functionChunk = Chunk(parent: chunk, arity: Byte(expr.analyzedParams.params.count), depth: Byte(scopeDepth))
		let functionCompiler = ChunkCompiler(scopeDepth: scopeDepth + 1, parent: self)

		// Define the params for this function
		for (i, parameter) in expr.analyzedParams.paramsAnalyzed.enumerated() {
			functionCompiler.localsTable[parameter.name] = Byte(i)
			functionChunk.emit(opcode: .setLocal, line: parameter.location.line)
			functionChunk.emit(byte: Byte(i), line: parameter.location.line)
		}

		for expr in expr.bodyAnalyzed.exprsAnalyzed {
			try expr.accept(functionCompiler, functionChunk)
		}

		// We always want to emit a return at the end of a function
		functionChunk.emit(opcode: .return, line: UInt32(expr.location.end.line))

		// Store the upvalue count
		functionChunk.upvalueCount = Byte(functionCompiler.upvalues.count)

		let subchunkID = Byte(chunk.subchunks.count)
		chunk.subchunks.append(functionChunk)
		chunk.emitClosure(subchunkID: subchunkID, line: UInt32(expr.location.line))
	}

	public func visit(_ expr: AnalyzedBlockExpr, _ chunk: Chunk) throws {
		for expr in expr.exprsAnalyzed {
			try expr.accept(self, chunk)
		}
	}

	public func visit(_ expr: AnalyzedWhileExpr, _ chunk: Chunk) throws {}

	public func visit(_ expr: AnalyzedParamsExpr, _ chunk: Chunk) throws {}

	public func visit(_ expr: AnalyzedReturnExpr, _ chunk: Chunk) throws {}

	public func visit(_ expr: AnalyzedMemberExpr, _ chunk: Chunk) throws {}

	public func visit(_ expr: AnalyzedDeclBlock, _ chunk: Chunk) throws {}

	public func visit(_ expr: AnalyzedStructExpr, _ chunk: Chunk) throws {}

	public func visit(_ expr: AnalyzedVarDecl, _ chunk: Chunk) throws {}

	public func visit(_ expr: AnalyzedLetDecl, _ chunk: Chunk) throws {}

	// MARK: Helpers

	// Lookup the variable by name. If we've got it in our locals, just return the slot
	// for that variable. If we don't, search parent chunks to see if they've got it. If
	// they do, we've got an upvalue.
	public func resolveVariable(named name: String) -> (Opcode, Byte)? {
		if let slot = resolveLocal(named: name) {
			return (.getLocal, slot)
		}

		if let slot = resolveUpvalue(named: name) {
			return (.getUpvalue, slot)
		}

		return nil
	}

	// Just look up the var in our locals
	public func resolveLocal(named name: String) -> Byte? {
		localsTable[name]
	}

	// Search parent chunks for the variable
	private func resolveUpvalue(named name: String) -> Byte? {
		guard let parent else { return nil }

		// If our immediate parent has the variable, we return an upvalue.
		if let local = parent.resolveLocal(named: name) {
			// Since it's in the immediate parent, we mark the upvalue as captured.
			parent.captures.append(name)
			return addUpvalue(local, isLocal: true)
		}

		// Check for upvalues in the parent. We don't need to mark the upvalue where it's found
		// as captured since the immediate child of the owning scope will handle that in its
		// resolveUpvalue call.
		if let local = parent.resolveUpvalue(named: name) {
			return addUpvalue(local, isLocal: false)
		}

		return nil
	}

	private func addUpvalue(_ index: Byte, isLocal: Bool) -> Byte {
//		for (int i = 0; i < upvalueCount; i++) {
//			Upvalue* upvalue = &compiler->upvalues[i];
//			if (upvalue->index == index && upvalue->isLocal == isLocal) {
//				return i;
//			}
//		}

		// If we've already got it, return it
		for (i, upvalue) in upvalues.enumerated() {
			if upvalue.index == index, upvalue.isLocal {
				return Byte(i)
			}
		}

		// Otherwise add a new one
		upvalues.append((index: index, isLocal: isLocal))

		return Byte(upvalues.count)
	}
}
