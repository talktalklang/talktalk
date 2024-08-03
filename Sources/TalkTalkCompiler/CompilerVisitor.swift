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

	public func visit(_ expr: AnalyzedDefExpr, _ chunk: Chunk) throws {}

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

	public func visit(_ expr: AnalyzedVarExpr, _ chunk: Chunk) throws {}

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

	public func visit(_ expr: AnalyzedIfExpr, _ chunk: Chunk) throws {}

	public func visit(_ expr: AnalyzedFuncExpr, _ chunk: Chunk) throws {}

	public func visit(_ expr: AnalyzedBlockExpr, _ chunk: Chunk) throws {}

	public func visit(_ expr: AnalyzedWhileExpr, _ chunk: Chunk) throws {}

	public func visit(_ expr: AnalyzedParamsExpr, _ chunk: Chunk) throws {}

	public func visit(_ expr: AnalyzedReturnExpr, _ chunk: Chunk) throws {}

	public func visit(_ expr: AnalyzedMemberExpr, _ chunk: Chunk) throws {}

	public func visit(_ expr: AnalyzedDeclBlock, _ chunk: Chunk) throws {}

	public func visit(_ expr: AnalyzedStructExpr, _ chunk: Chunk) throws {}

	public func visit(_ expr: AnalyzedVarDecl, _ chunk: Chunk) throws {}

	public func visit(_ expr: AnalyzedLetDecl, _ chunk: Chunk) throws {}
}
