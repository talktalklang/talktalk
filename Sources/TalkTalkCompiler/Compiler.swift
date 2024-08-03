//
//  Compiler.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/2/24.
//

import TalkTalkBytecode
import TalkTalkAnalysis

public struct Compiler {
	public var number = 0
	public var chunk: Chunk
	public let analyzedExprs: [any AnalyzedExpr]

	public init(analyzedExprs: [any AnalyzedExpr]) {
		self.analyzedExprs = analyzedExprs
		self.chunk = Chunk()
	}

	public mutating func compile() throws -> Chunk {
		let visitor = CompilerVisitor()

		for expr in analyzedExprs {
			try expr.accept(visitor, chunk)
		}

		// Always emit a `return` since we start with a frame
		chunk.emit(opcode: .return, line: 0)
		return chunk
	}
}
