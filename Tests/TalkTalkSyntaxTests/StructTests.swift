//
//  StructTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/23/24.
//

import TalkTalkCore
import Testing

struct StructTests {
	@Test("Parses struct conformances") func conformances() throws {
		let ast = try Parser.parse("""
		struct Foo: Bar {}
		""")

		let structExpr = ast[0].cast(StructDeclSyntax.self)
		#expect(structExpr.name == "Foo")
		#expect(structExpr.conformances.map(\.identifier.lexeme) == ["Bar"])
	}

	@Test("Parses struct") func structs() throws {
		let ast = try Parser.parse("""
		struct Foo {
			var age: int
		}

		foo = Foo(age: 123)
		foo.age
		""")

		let structExpr = ast[0].cast(StructDeclSyntax.self)
		#expect(structExpr.name == "Foo")

		let varDecl = structExpr.body.decls[0].cast(PropertyDeclSyntax.self)
		#expect(varDecl.name.lexeme == "age")
		#expect(varDecl.typeAnnotation?.description == "int")

		let fooDef = ast[1].cast(ExprStmtSyntax.self).expr.cast(DefExprSyntax.self)
		#expect(fooDef.receiver.cast(VarExprSyntax.self).name == "foo")

		let fooInit = fooDef.value.cast(CallExprSyntax.self)
		#expect(fooInit.callee.description == "Foo")
		#expect(fooInit.args[0].label?.lexeme == "age")
		#expect(fooInit.args[0].value.cast(LiteralExprSyntax.self).value == .int(123))

		let fooMember = ast[2].cast(ExprStmtSyntax.self).expr.cast(MemberExprSyntax.self)
		#expect(fooMember.receiver?.cast(VarExprSyntax.self).name == "foo")
		#expect(fooMember.property == "age")
	}

	@Test("Parses struct with let decl") func structsLet() throws {
		let ast = try Parser.parse("""
		struct Foo {
			let age: int

			init(age: int) {
				self.age = age
			}
		}

		foo = Foo(age: 123)
		foo.age
		""")

		let structExpr = ast[0].cast(StructDeclSyntax.self)
		#expect(structExpr.name == "Foo")

		let varDecl = structExpr.body.decls[0].cast(PropertyDeclSyntax.self)
		#expect(varDecl.name.lexeme == "age")
		#expect(varDecl.typeAnnotation?.description == "int")

		let fooDef = ast[1].cast(ExprStmtSyntax.self).expr.cast(DefExprSyntax.self)
		#expect(fooDef.receiver.cast(VarExprSyntax.self).name == "foo")

		let fooInit = fooDef.value.cast(CallExprSyntax.self)
		#expect(fooInit.callee.description == "Foo")
		#expect(fooInit.args[0].label?.lexeme == "age")
		#expect(fooInit.args[0].value.cast(LiteralExprSyntax.self).value == .int(123))

		let fooMember = ast[2].cast(ExprStmtSyntax.self).expr.cast(MemberExprSyntax.self)
		#expect(fooMember.receiver?.cast(VarExprSyntax.self).name == "foo")
		#expect(fooMember.property == "age")
	}

	@Test("Generics?") func generics() throws {
		let ast = try Parser.parse("""
		struct Foo<Bar> {
			var fizz: Bar
		}

		Foo<int>()
		""")

		let structExpr = ast[0].cast(StructDeclSyntax.self)
		#expect(structExpr.name == "Foo")

		let paramNames = structExpr.typeParameters.map(\.identifier.lexeme)
		#expect(paramNames == ["Bar"])

		let calleeExpr = try #require(ast[1].cast(ExprStmtSyntax.self).expr.cast(CallExprSyntax.self).callee.as(TypeExprSyntax.self))
		#expect(calleeExpr.identifier.lexeme == "Foo")
		#expect(calleeExpr.genericParams.map(\.identifier.lexeme) == ["int"])
	}

	@Test("Nested generics") func nestedGenerics() throws {
		let ast = try Parser.parse("Foo<Fizz<Buzz>>")[0]
			.cast(ExprStmtSyntax.self).expr
			.cast(TypeExprSyntax.self)

		#expect(ast.identifier.lexeme == "Foo")
		#expect(ast.genericParams[0].identifier.lexeme == "Fizz")
		#expect(ast.genericParams[0].genericParams[0].identifier.lexeme == "Buzz")
	}

	@Test("Generic properties") func genericProperties() throws {
		let ast = try Parser.parse("""
		struct Foo<Bar> {}
		struct Fizz<Buzz> {
			var foo: Foo<Buzz>
		}
		""")

		let structExpr = ast[1].cast(StructDeclSyntax.self)
		#expect(structExpr.name == "Fizz")

		let paramNames = structExpr.typeParameters.map(\.identifier.lexeme)
		#expect(paramNames == ["Buzz"])

		let property = structExpr.body.decls[0].cast(PropertyDeclSyntax.self)
		#expect(property.typeAnnotation?.identifier.lexeme == "Foo")
	}

	@Test("Can parse a static method") func staticMethod() throws {
		let parsed = try Parser.parse(
			"""
			struct Basic {
				static func hello() {}
			}
			"""
		)

		let structDef = try #require(parsed[0] as? StructDecl)
		let method = structDef.body.decls[0].cast(FuncExprSyntax.self)
		#expect(method.name?.lexeme == "hello")
		#expect(method.isStatic)
	}

	@Test("Can parse a static var") func staticVar() throws {
		let parsed = try Parser.parse(
			"""
			struct Basic {
				static var hello: String
			}
			"""
		)

		let structDef = try #require(parsed[0] as? StructDecl)
		let property = structDef.body.decls[0].cast(PropertyDeclSyntax.self)
		#expect(property.name.lexeme == "hello")
		#expect(property.isStatic)
	}

	@Test("Can parse a static let") func staticLet() throws {
		let parsed = try Parser.parse(
			"""
			struct Basic {
				static let hello: String
			}
			"""
		)

		let structDef = try #require(parsed[0] as? StructDecl)
		let method = structDef.body.decls[0].cast(PropertyDeclSyntax.self)
		#expect(method.name.lexeme == "hello")
		#expect(method.isStatic)
	}
}
