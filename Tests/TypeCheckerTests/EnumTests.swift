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

			match Thing.foo("sup") {
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
		#expect(enumType.cases[0].attachedTypes[0] == .typeVar("Wrapped", 100)) // Make sure int doesn't leak to outer generic

		let wrappedIntVar = syntax[1].cast(MatchStatementSyntax.self)
			.cases[0].body[0]
			.cast(ExprStmtSyntax.self).expr

		#expect(context[wrappedIntVar] == .type(.base(.int)))

		#expect(enumType.cases[0].attachedTypes[0] == .typeVar("Wrapped", 100)) // Make sure we're still good here

		let wrappedStringVar = syntax[2].cast(MatchStatementSyntax.self)
			.cases[0].body[0]
			.cast(ExprStmtSyntax.self).expr

		#expect(context[wrappedStringVar] == .type(.base(.string)))

		#expect(enumType.cases[0].attachedTypes[0] == .typeVar("Wrapped", 100)) // Make sure we're still good here
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
		let enumType = Instance.extract(from: result.asType(in: context))!.type as! EnumType
		#expect(enumType.name == "Thing")

		let arg = syntax[2].cast(ExprStmtSyntax.self).expr
			.cast(CallExprSyntax.self).args[0].value

		#expect(context[arg] == .type(.instantiatable(enumType)))

		#expect(enumType.cases == [
			EnumCase(type: enumType, name: "foo", index: 0, attachedTypes: [.base(.string)]),
			EnumCase(type: enumType, name: "bar", index: 1, attachedTypes: [.base(.int)]),
		]
		)
	}

	@Test("Can infer self") func enumSelf() throws {
		let syntax = try Parser.parse(
			"""
			enum Thing {
				case foo
				case bar

				func isFoo() {
					self == .foo
				}
			}
			"""
		)

		let context = try infer(syntax)
		let enumType = syntax[0].cast(EnumDeclSyntax.self)
		let enumInferenceType = try EnumType.extract(from: context.get(enumType))!
		let fn = enumType.body.decls[2].cast(FuncExprSyntax.self)
		let binaryExpr = fn.body.stmts[0]
			.cast(ExprStmtSyntax.self)
			.expr.cast(BinaryExprSyntax.self)
		let selfVar = binaryExpr.lhs.cast(VarExprSyntax.self)
		let foo = binaryExpr.rhs.cast(MemberExprSyntax.self)

		// Make sure we can infer `self`
		let selfVarType = try context.get(selfVar)
		#expect(selfVarType == InferenceResult.type(.selfVar(.instantiatable(enumInferenceType))))

		// Make sure we can infer `.foo`
		let fooType = try context.get(foo)
		#expect(fooType == .type(.instantiatable(enumInferenceType)))

		// Make sure the method has the right type
		let fnType = try context.applySubstitutions(to: context.get(fn))
		#expect(fnType == .function([], .base(.bool)))
	}

	@Test("Can infer protocol conformance") func protocols() throws {
		let syntax = try Parser.parse(
			"""
			protocol Greetable {
				func fizz() -> String
			}

			enum Thing: Greetable {
				case foo
				case bar

				func fizz() {
					"buzz"
				}
			}

			func greet(greetable: Greetable) {
				greetable.fizz()
			}

			greet(Thing.foo)
			"""
		)

		let context = try infer(syntax)
		let ret = context[syntax[3]]!.asType(in: context)

		#expect(ret == .base(.string))
	}
}
