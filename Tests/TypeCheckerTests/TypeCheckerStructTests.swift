//
//  TypeCheckerStructTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/25/24.
//

import TalkTalkCore
import Testing
@testable import TypeChecker

@MainActor
struct TypeCheckerStructTests: TypeCheckerTest {
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
		#expect(structType.member(named: "name", in: context) == .type(.base(.string)))
		#expect(structType.member(named: "age", in: context) == .type(.base(.int)))
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

	@Test("Types self return") func selfReturn() throws {
		let syntax = try Parser.parse(
			"""
			struct Person {
				func sup() {
					self
				}
			}

			Person().sup()
			"""
		)

		let context = try infer(syntax)
		let structType = StructType.extractType(from: context[syntax[0]])!

		guard case let .function(_, returnType) = structType.member(named: "sup", in: context)?.asType(in: context) else {
			#expect(Bool(false)); return
		}

		#expect(returnType == .type(.selfVar(.instantiatable(.struct(structType)))))
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
		#expect(structType.member(named: "greet", in: context)?.asType(in: context) == .function([], .type(.base(.string))))

		let result1 = context[syntax[1]]
		let expected1 = InferenceResult.type(.function([], .type(.base(.string))))
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
		#expect(context[syntax[3]] == .type(.base(.string)))
	}

	@Test("Type checks static let") func staticLet() throws {
		let syntax = try Parser.parse(
			"""
			struct Person {
				static let name: String
			}

			Person.name
			"""
		)

		let context = try infer(syntax)

		#expect(context[syntax[1]] == .type(.base(.string)))
	}

	@Test("Type checks static var") func staticVar() throws {
		let syntax = try Parser.parse(
			"""
			struct Person {
				static var age: int
			}

			Person.age
			"""
		)

		let context = try infer(syntax)

		#expect(context[syntax[1]] == .type(.base(.int)))
	}

	@Test("Type checks static func") func staticFunc() throws {
		let syntax = try Parser.parse(
			"""
			struct Person {
				static func age() {
					123
				}
			}

			Person.age
			"""
		)

		let context = try infer(syntax)

		#expect(context[syntax[1]]?.asType(in: context) == .function([], .type(.base(.int))))
	}
}
