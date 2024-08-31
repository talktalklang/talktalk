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
	func infer(_ expr: [any Syntax]) throws -> InferenceContext {
		let inferencer = Inferencer()
		return inferencer.infer(expr).solve().solveDeferred()
	}
}
