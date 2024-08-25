//
//  TypeCheckerTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/25/24.
//

import Testing
@testable import TypeChecker
import TalkTalkSyntax

struct TypeCheckerTests {
	func infer(_ expr: any Syntax, sourceLocation: Testing.SourceLocation = #_sourceLocation) throws -> InferenceResult {
		let inferencer = InferenceVisitor()
		let context = inferencer.infer([expr])

		return try #require(context.environment[expr], sourceLocation: sourceLocation)
	}

	@Test("Infers int literal") func intLiteral() throws {
		let expr = try Parser.parse("123")[0]
		let result = try infer(expr)
		#expect(result == .type(.base(.int)))
	}

	@Test("Infers string literal") func stringLiteral() throws {
		let expr = try Parser.parse(#""hello world""#)[0]
		let result = try infer(expr)
		#expect(result == .type(.base(.string)))
	}

	@Test("Infers bool literal") func boolLiteral() throws {
		let expr = try Parser.parse("true")[0]
		let result = try infer(expr)
		#expect(result == .type(.base(.bool)))
	}

	@Test("Infers identity function") func identityFunction() throws {
		let expr = try Parser.parse("func(x) { x }")[0]
		let result = try infer(expr)
		#expect(
			result == .scheme(
				Scheme(
					variables: [TypeVariable("x", 0)],
					type: .function([.variable("x", 0)], .variable("x", 0))
				)
			)
		)
	}

	@Test("Infers binary expr with ints") func binaryInts() throws {
		let expr = try Parser.parse("10 + 20")[0]
		let result = try infer(expr)
		// What should go here?
	}

	@Test("Infers binary expr with strings") func binaryStrings() throws {
		let expr = try Parser.parse(#""hello " + "world""#)[0]
		let result = try infer(expr)
		// What should go here?
	}
}
