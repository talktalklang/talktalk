//
//  BoundPattern.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/10/24.
//

import TypeChecker
import TalkTalkAnalysis
import TalkTalkBytecode

struct BoundPattern {
	let pattern: Pattern?
	let root: any AnalyzedSyntax
	let arguments: [any AnalyzedExpr]

	static func bind(_ syntax: AnalyzedCaseStmt) -> BoundPattern? {
		switch syntax.patternAnalyzed {
		case let syntax as AnalyzedCallExpr:
			guard case let .pattern(pattern) = syntax.inferenceType else {
				return nil
			}

			return BoundPattern(pattern: pattern, root: syntax, arguments: syntax.argsAnalyzed.map(\.expr))
		default:
			return BoundPattern(pattern: nil, root: syntax, arguments: [])
		}
	}

	init(pattern: Pattern?, root: any AnalyzedSyntax, arguments: [any AnalyzedExpr]) {
		self.pattern = pattern
		self.root = root
		self.arguments = arguments
	}

	func emit(into chunk: Chunk, with compiler: ChunkCompiler) throws {
		switch root {
		case let syntax as AnalyzedCallExpr:
			()
		default:
			try root.accept(compiler, chunk)
		}
	}
}
