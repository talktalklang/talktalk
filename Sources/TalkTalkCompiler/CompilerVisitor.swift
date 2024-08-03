//
//  CompilerVisitor.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/2/24.
//

import TalkTalkAnalysis
import TalkTalkBytecode

public struct CompilerVisitor: AnalyzedVisitor {
	public typealias Value = Void

	public func visit(_ expr: AnalyzedCallExpr, _ chunk: Chunk) throws {}

	public func visit(_ expr: AnalyzedDefExpr, _ chunk: Chunk) throws {
		// Put the value onto the stack
		try expr.valueAnalyzed.accept(self, chunk)

		chunk.emit(opcode: .setLocal, local: expr.name.lexeme, line: expr.location.line)
	}

	public func visit(_ expr: AnalyzedErrorSyntax, _ chunk: Chunk) throws {}

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
		guard chunk.localsTable[expr.name] != nil else {
			throw CompilerError.unknownLocal(expr.name)
		}

		chunk.emit(opcode: .getLocal, local: expr.name, line: expr.location.line)
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

	public func visit(_ expr: AnalyzedFuncExpr, _ chunk: Chunk) throws {}

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
}
