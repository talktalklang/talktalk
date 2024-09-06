//
//  TypeCheckerTest.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/31/24.
//

import Testing
import TalkTalkSyntax
@testable import TypeChecker

protocol TypeCheckerTest {}
extension TypeCheckerTest {
	func infer(_ expr: [any Syntax], imports: [InferenceContext] = [], sourceLocation: Testing.SourceLocation = #_sourceLocation) throws -> InferenceContext {
		let inferencer = try Inferencer(imports: imports)
		let context = inferencer.infer(expr).solve().solveDeferred()
		return context
	}
}
