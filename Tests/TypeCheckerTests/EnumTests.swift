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
	@Test("Can infer an enum type") func basic() throws {
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

	@Test("Can infer a generic enum type") func generics() throws {
		let syntax = try Parser.parse(
			"""
			enum Thing<Wrapped> {
				case foo(Wrapped)
			}

			match Thing.foo(123) {
			case .foo(let wrapped):
				wrapped
			}
			"""
		)

		let context = try infer(syntax)
		let enumResult = try context.get(syntax[0])
		let enumType = try #require(EnumType.extract(from: enumResult))

		#expect(enumType.name == "Thing")
		#expect(enumType.cases.count == 1)

		#expect(enumType.cases[0].attachedTypes.count == 1)
		#expect(enumType.cases[0].attachedTypes[0] == .typeVar("Wrapped", 86)) // Make sure int doesn't leak to outer generic

		let wrappedVar = syntax[1].cast(MatchStatementSyntax.self)
			.cases[0].body[0]
			.cast(ExprStmtSyntax.self).expr

		#expect(context[wrappedVar] == .type(.base(.int)))
	}

	@Test("Can infer a case") func cases() throws {
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
		let enumType = try #require(EnumType.extract(from: enumResult))
		#expect(enumType.name == "Thing")
	}

	@Test("Can infer out of order decls") func outOfOrder() throws {
		let syntax = try Parser.parse(
			"""
			enum A {
				case foo(B)
			}

			enum B {
				case fizz
			}
			"""
		)

		let context = try infer(syntax)
		#expect(context.errors == [])

		let enumResult = try context.get(syntax[0])
		let enumType = try #require(EnumType.extract(from: enumResult))
		#expect(enumType.name == "A")

		let b = try #require(EnumType.extract(from: .type(context.applySubstitutions(to: enumType.cases[0].attachedTypes[0]))))
		#expect(b.name == "B")
	}

	@Test("Can infer an unqualified case") func unqualifiedCase() throws {
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
		let enumType = EnumType.extract(from: result)!
		#expect(enumType.name == "Thing")

		let arg = syntax[2].cast(ExprStmtSyntax.self).expr
			.cast(CallExprSyntax.self).args[0].value

		#expect(enumType.cases == [
			EnumCase(typeName: "Thing", name: "foo", index: 0, attachedTypes: [.base(.string)]),
			EnumCase(typeName: "Thing", name: "bar", index: 1, attachedTypes: [.base(.int)]),
		]
		)
	}
}
