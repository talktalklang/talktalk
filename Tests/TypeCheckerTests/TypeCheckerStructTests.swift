//
//  TypeCheckerStructTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/25/24.
//

import Testing
import TalkTalkSyntax
@testable import TypeChecker

@MainActor
struct TypeCheckerStructTests {
	func infer(_ expr: [any Syntax]) throws -> InferenceContext {
		let inferencer = InferenceVisitor()
		return inferencer.infer(expr)
	}

	@Test("Types struct type") func structType() throws {
		let syntax = try Parser.parse(
			"""
			struct Person {}
			"""
		)

		let context = try infer(syntax)
		let structType = try #require(StructType.extractType(from: context[syntax[0]]))
		#expect(structType.name == "Person")
	}

	@Test("Types instance type") func instanceType() throws {
		let syntax = try Parser.parse(
			"""
			struct Person {}
			Person()
			"""
		)

		let context = try infer(syntax)
		let structType = try #require(StructType.extractInstance(from: context[syntax[1]]))
		#expect(structType.name == "Person")
	}

	@Test("Types instance properties") func instanceProperty() throws {
		let syntax = try Parser.parse(
			"""
			struct Person {
				var name: String
				var age: int
			}
			"""
		)

		let context = try infer(syntax)
		let structType = try #require(StructType.extractType(from: context[syntax[0]]))
		#expect(structType.properties["name"] == .type(.base(.string)))
		#expect(structType.properties["age"] == .type(.base(.int)))
	}

	@Test("Types instance methods") func instanceMethod() throws {
		let syntax = try Parser.parse(
			"""
			struct Person {
				func greet() {
					"hi"
				}
			}

			Person().greet
			Person().greet()
			"""
		)

		let context = try infer(syntax)
		let structType = try #require(StructType.extractType(from: context[syntax[0]]))
		#expect(structType.methods["greet"] == .type(.function([], .base(.string))))

		#expect(context[syntax[1]] == .type(.function([], .base(.string))))
		#expect(context[syntax[2]] == .type(.base(.string)))
	}
}
