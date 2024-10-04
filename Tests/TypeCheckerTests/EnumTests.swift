//
//  EnumTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/5/24.
//

import TalkTalkCore
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

		let context = try solve(syntax)
		let enumResult = context[syntax[0]]!
		let enumType = try #require(Enum.extract(from: enumResult))

		#expect(enumType.name == "Thing")
		#expect(enumType.cases.count == 2)

		#expect(enumType.cases["foo"]!.attachedTypes.count == 1)
		#expect(enumType.cases["foo"]!.attachedTypes[0] == .type(.base(.string)))

		#expect(enumType.cases["bar"]!.attachedTypes.count == 1)
		#expect(enumType.cases["bar"]!.attachedTypes[0] == .type(.base(.int)))
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

		let context = try solve(syntax, verbose: true)
		let instance = Instance<Enum.Case>.extract(from: context[syntax[1]]!)!
		#expect(instance.type.type.name == "Thing")
		#expect(instance.type.name == "foo")
	}

	@Test("Can infer a generic enum type") func generics() throws {
		let syntax = try Parser.parse(
			"""
			enum Thing<Wrapped> {
				case foo(Wrapped)
			}

			Thing.foo(123)
			Thing.foo("123")

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

		let context = try solve(syntax, verbose: true)
		let enumType = try #require(Enum.extract(from: context[syntax[0]]!))

		#expect(enumType.name == "Thing")
		#expect(enumType.cases.count == 1)

		#expect(enumType.cases["foo"]!.attachedTypes.count == 1)
		#expect(enumType.cases["foo"]!.attachedTypes[0] == .type(.typeVar("Wrapped", 1, isGeneric: true))) // Make sure int doesn't leak to outer generic

		let wrappedInt = Instance<Enum.Case>.extract(from: context[syntax[1]]!)
		#expect(wrappedInt?.substitutions[.new("Wrapped", 1, isGeneric: true)] == .base(.int))

		let wrappedString = Instance<Enum.Case>.extract(from: context[syntax[2]]!)
		#expect(wrappedString?.substitutions[.new("Wrapped", 1, isGeneric: true)] == .base(.string))


		let wrappedIntVar = syntax[3].cast(MatchStatementSyntax.self)
			.cases[0].body[0]
			.cast(ExprStmtSyntax.self).expr

		#expect(context.children[1][wrappedIntVar] == .base(.int))

		let wrappedStringVar = syntax[4].cast(MatchStatementSyntax.self)
			.cases[0].body[0]
			.cast(ExprStmtSyntax.self).expr

		#expect(context.children[2][wrappedStringVar] == .base(.string))
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

		let context = try solve(syntax)

		let enumType = try #require(Enum.extract(from: context[syntax[0]]!))
		#expect(enumType.name == "A")

		let b = try #require(Enum.extract(from: context.applySubstitutions(to: enumType.cases["foo"]!.attachedTypes[0])))
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
		let enumType = InstanceV1<EnumTypeV1>.extract(from: result.asType(in: context))!.type
		#expect(enumType.name == "Thing")

		let arg = syntax[2].cast(ExprStmtSyntax.self).expr
			.cast(CallExprSyntax.self).args[0].value

		let instance = try #require(InstanceV1<EnumTypeV1>.extract(from: context[arg]!.asType(in: context)))
		#expect(enumType == instance.type)

		#expect(context[arg] == .type(.instanceV1(.enumType(instance))))

		#expect(enumType.cases == [
			EnumCase(type: enumType, name: "foo", attachedTypes: [.base(.string)]),
			EnumCase(type: enumType, name: "bar", attachedTypes: [.base(.int)]),
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
		let enumInferenceType = try EnumTypeV1.extract(from: context.get(enumType))!
		let fn = enumType.body.decls[2].cast(FuncExprSyntax.self)
		let binaryExpr = fn.body.stmts[0]
			.cast(ExprStmtSyntax.self)
			.expr.cast(BinaryExprSyntax.self)
		let selfVar = binaryExpr.lhs.cast(VarExprSyntax.self)
		let foo = binaryExpr.rhs.cast(MemberExprSyntax.self)

		// Make sure we can infer `self`
		let selfVarType = try context.get(selfVar)
		#expect(selfVarType == InferenceResult.type(.selfVar(.instantiatable(.enumType(enumInferenceType)))))

		// Make sure we can infer `.foo`
		let fooType = try context.get(foo)
		#expect(fooType == .type(.instantiatable(.enumType(enumInferenceType))))

		// Make sure the method has the right type
		let fnType = try context.applySubstitutions(to: context.get(fn))
		#expect(fnType == .function([], .type(.base(.bool))))
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
