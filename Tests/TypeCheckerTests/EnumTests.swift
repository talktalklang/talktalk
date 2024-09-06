//
//  EnumTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/5/24.
//

import TalkTalkSyntax
import Testing
@testable import TypeChecker

@MainActor
struct EnumTests: TypeCheckerTest {
	@Test("Can typecheck an enum type") func basic() throws {
		let syntax = try Parser.parse(
		"""
		enum Thing {
			case foo(String)
			case bar(int)
		}
		"""
		)

		let context = try infer(syntax)
		let enumResult = try context.get(syntax[0])
		let enumType = try #require(EnumType.extract(from: enumResult))

		#expect(enumType.name == "Thing")
		#expect(enumType.cases.count == 2)

		#expect(enumType.cases[0].attachedTypes.count == 1)
		#expect(enumType.cases[0].attachedTypes[0] == .base(.string))

		#expect(enumType.cases[1].attachedTypes.count == 1)
		#expect(enumType.cases[1].attachedTypes[0] == .base(.int))
	}

	@Test("Can typecheck a case") func cases() throws {
		let syntax = try Parser.parse(
		"""
		enum Thing {
			case foo(String)
			case bar(int)
		}

		Thing.foo("sup")
		"""
		)

		let context = try infer(syntax)

		let enumResult = try context.get(syntax[1])
		let enumType = try #require(EnumCase.extract(from: enumResult))
		#expect(enumType.name == "foo")
		#expect(enumType.attachedTypes[0] == .base(.string))
	}

	@Test("Can typecheck an unqualified case") func unqualifiedCase() throws {
		let syntax = try Parser.parse(
		"""
		enum Thing {
			case foo(String)
			case bar(int)
		}

		func check(thing: Thing) {
			thing
		}

		check(.foo("hello"))
		"""
		)

		let context = try infer(syntax)

		let result = try context.get(syntax[2])
		let enumType = EnumType.extract(from: result)
		#expect(enumType?.name == "Thing")

		let arg = syntax[2].cast(ExprStmtSyntax.self).expr
			.cast(CallExprSyntax.self).args[0].value
		#expect(context[arg]?.asType(in: context) == .enumCase(
			enumType!,
			EnumCase(typeName: "Thing", name: "foo", attachedTypes: [.base(.string)]))
		)
	}
}
