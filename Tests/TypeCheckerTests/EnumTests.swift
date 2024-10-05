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
		#expect(enumType.cases["foo"]!.attachedTypes[0] == .resolved(.base(.string)))

		#expect(enumType.cases["bar"]!.attachedTypes.count == 1)
		#expect(enumType.cases["bar"]!.attachedTypes[0] == .resolved(.base(.int)))
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

		let context = try solve(syntax)
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

		let context = try solve(syntax)
		let enumType = try #require(Enum.extract(from: context[syntax[0]]!))

		#expect(enumType.name == "Thing")
		#expect(enumType.cases.count == 1)

		#expect(enumType.cases["foo"]!.attachedTypes.count == 1)
		#expect(enumType.cases["foo"]!.attachedTypes[0] == .resolved(.typeVar("Wrapped", 1, isGeneric: true))) // Make sure int doesn't leak to outer generic

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

		let foo = context.applySubstitutions(to: enumType.cases["foo"]!.attachedTypes[0])
		let b = try #require(Enum.extract(from: foo))
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

		let context = try solve(syntax)

		let result = context.find(syntax[0])!
		let enumType = Enum.extract(from: result)!
		#expect(enumType.name == "Thing")

		let arg = syntax[2].cast(ExprStmtSyntax.self).expr
			.cast(CallExprSyntax.self).args[0].value


		let instance = try #require(Instance<Enum.Case>.extract(from: context.find(arg)!))
		#expect(instance.type.type.name == "Thing")
		#expect(context.find(arg) == .instance(.enumCase(instance)))
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

		let context = try solve(syntax)
		let enumType = syntax[0].cast(EnumDeclSyntax.self)
		let enumInferenceType = Enum.extract(from: context[enumType]!)!

		let fn = enumType.body.decls[2].cast(MethodDeclSyntax.self)
		let binaryExpr = fn.body.stmts[0]
			.cast(ExprStmtSyntax.self)
			.expr.cast(BinaryExprSyntax.self)
		let selfVar = binaryExpr.lhs.cast(VarExprSyntax.self)
		let foo = binaryExpr.rhs.cast(MemberExprSyntax.self)

		// Make sure we can infer `self`
		let selfVarType = context.find(selfVar)!
		#expect(selfVarType == .self(enumInferenceType))

		// Make sure we can infer `.foo`
		let instance = Instance<Enum.Case>.extract(from: context.find(foo)!)
		#expect(instance?.name == "foo")
		#expect(instance?.type.type.name == "Thing")

		// Make sure the method has the right type
		#expect(context.find(fn) == .function([], .resolved(.base(.bool))))
	}

	@Test("Can infer protocol conformance", .disabled("waiting on protocols")) func protocols() throws {
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
