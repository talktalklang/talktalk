//
//  TypeCheckerTest.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/31/24.
//

import TalkTalkSyntax
@testable import TypeChecker

protocol TypeCheckerTest {}
extension TypeCheckerTest {
	func infer(_ expr: [any Syntax], imports: [InferenceContext] = []) throws -> InferenceContext {
		let inferencer = try Inferencer(imports: imports)
		return inferencer.infer(expr).solve().solveDeferred()
	}
}
