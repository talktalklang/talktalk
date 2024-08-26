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

		let context = try infer(syntax)
		#expect(context[syntax[1]] == .type(.base(.string)))
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
		#expect(structType.methods["greet"] == .scheme(
			Scheme(name: "greet", variables: [], type: .function([], .base(.string)))
		))

		#expect(context[syntax[1]] == .type(.function([], .base(.string))))
		#expect(context[syntax[2]] == .type(.base(.string)))
	}

	@Test("Type checks chained property access") func chaining() throws {
		let syntax = try Parser.parse(
			"""
			struct PersonInfo {
				var name: String
			}

			struct Person {
				var info: PersonInfo
			}

			Person(info: PersonInfo(name: "Pat")).info
			Person(info: PersonInfo(name: "Pat")).info.name
			"""
		)

		let context = try infer(syntax)

		let personInfoInstance = StructType.extractInstance(from: context[syntax[2]])
		let personInfoStructType = try #require(personInfoInstance)

		#expect(personInfoStructType.name == "PersonInfo")
		#expect(context[syntax[3]] == .type(.base(.string)))
	}
}
