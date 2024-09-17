//
//  TypeCheckerTest.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/31/24.
//

import TalkTalkSyntax
import Testing
@testable import TypeChecker

protocol TypeCheckerTest {}
extension TypeCheckerTest {
	func infer(
		_ expr: [any Syntax],
		imports: [InferenceContext] = [],
		expectedErrors: Int = 0,
		sourceLocation _: Testing.SourceLocation = #_sourceLocation
	) throws -> InferenceContext {
		let inferencer = try Inferencer(imports: imports)
		let context = inferencer.infer(expr).solve().solveDeferred()

		#expect(context.errors.count == expectedErrors)

		return context
	}
}
