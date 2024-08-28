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
		return inferencer.infer(expr).solve()
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
		print()
		let instance = try #require(StructType.extractInstance(from: context[syntax[1]]))
		#expect(instance.name == "Person")
	}

	@Test("Types instance properties with base types") func instanceProperty() throws {
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
		#expect(structType.member(named: "name") == .type(.base(.string)))
		#expect(structType.member(named: "age") == .type(.base(.int)))
	}

	@Test("Types custom init") func customInit() throws {
		let syntax = try Parser.parse(
			"""
			struct Person {
				var name: String

				init() {
					self.name = "Pat"
				}
			}

			Person().name
			"""
		)

		let context = try infer(syntax)
		#expect(context[syntax[1]] == .type(.base(.string)))
	}

	@Test("Types self member access") func selfMember() throws {
		let syntax = try Parser.parse(
			"""
			struct Person {
				var name: String

				init() {
					self.name = "Pat"
				}

				func getName() {
					self.name
				}
			}

			Person().getName()
			"""
		)

		let context = try infer(syntax	)
		#expect(context[syntax[1]] == .type(.base(.string)))
	}

	@Test("Types instance methods") func instanceMethod() throws {
		let syntax = try Parser.parse(
			"""
			struct Person {
				init() {}

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
		#expect(structType.member(named: "greet") == .type(.function([], .base(.string))))

		let result1 = context[syntax[1]]
		let expected1 = InferenceResult.type(.function([], .base(.string)))
		#expect(result1 == expected1)

		let result2 = context[syntax[2]]
		let expected2 = InferenceResult.type(.base(.string))
		#expect(result2 == expected2)
	}

	@Test("Type checks chained property access") func chaining() throws {
		let syntax = try Parser.parse(
			"""
			struct PersonInfo {
				var name: String

				init(name) {
					self.name = name
				}
			}

			struct Person {
				var info: PersonInfo

				init(info) {
					self.info = info
				}
			}

			Person(info: PersonInfo(name: "Pat")).info
			Person(info: PersonInfo(name: "Pat")).info.name
			"""
		)

		let context = try infer(syntax)

		let personInfoInstance = StructType.extractInstance(from: context[syntax[2]])
		let personInfo = try #require(personInfoInstance)

		#expect(personInfo.name == "PersonInfo")
		#expect(context[syntax[3]] == .type(.base(.string)))
	}
}
