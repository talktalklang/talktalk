//
//  ABT.swift
//  
//
//  Created by Pat Nakajima on 7/19/24.
//

import Testing
import TalkTalkSyntax
import TalkTalkTyper

struct ABTTests {
	func ast(_ string: String) -> ProgramSyntax {
		let sourceFile = SourceFile(path: "ABTTests.tlk", source: string)
		return try! SyntaxTree.parse(source: sourceFile)
	}

	@Test("Binds String with let") func letString() {
		let abt = SemanticASTVisitor(ast: ast("""
		let foo = "sup"
		""")).visit()

		let decl = abt.cast(Program.self).declarations[0]
		#expect(decl.syntax.start.start == 0)
		#expect(decl.scope.locals["foo"]!.type.description == "String")
	}

	@Test("Binds String with var") func varString() {
		let abt = SemanticASTVisitor(ast: ast("""
		var foo = "sup"
		""")).visit()

		let decl = abt.cast(Program.self).declarations[0]
		#expect(decl.syntax.start.start == 0)
		#expect(decl.scope.locals["foo"]!.type.description == "String")
	}

	@Test("Binds Int with let") func letInt() {
		let abt = SemanticASTVisitor(ast: ast("""
		let foo = 123
		""")).visit()

		let decl = abt.cast(Program.self).declarations[0]
		#expect(decl.syntax.start.start == 0)
		#expect(decl.scope.locals["foo"]!.type.description == "Int")
	}

	@Test("Cannot reassign a `let`") func letReassign() throws {
		let abt = SemanticASTVisitor(ast: ast("""
		let foo = 123
		foo = 456
		""")).visit()

		#expect(!abt.scope.errors.isEmpty)
		#expect(abt.scope.errors[0].message.contains("Cannot reassign"))
	}

	@Test("Can assign a let before it's been assigned") func letAssign() throws {
		let abt = SemanticASTVisitor(ast: ast("""
		let foo
		foo = 456
		""")).visit()

		#expect(abt.scope.errors.isEmpty)
		#expect(abt.scope.locals["foo"]?.type.description == "Int")
	}

	@Test("Can reassign a var") func varReassign() throws {
		let abt = SemanticASTVisitor(ast: ast("""
		var foo = 123
		foo = 456
		""")).visit()

		#expect(abt.scope.errors.isEmpty)
		#expect(abt.scope.locals["foo"]?.type.description == "Int")
	}

	@Test("Binds String with var") func varInt() {
		let abt = SemanticASTVisitor(ast: ast("""
		var foo = 123
		""")).visit()

		let decl = abt.cast(Program.self).declarations[0]
		#expect(decl.syntax.start.start == 0)
		#expect(decl.scope.locals["foo"]!.type.description == "Int")
	}

	@Test("Binds Bool with let") func letBool() {
		let abt = SemanticASTVisitor(ast: ast("""
		let foo = true
		""")).visit()

		let decl = abt.cast(Program.self).declarations[0]
		#expect(decl.syntax.start.start == 0)
		#expect(decl.scope.locals["foo"]!.type.description == "Bool")
	}

	@Test("Binds String with var") func varBool() {
		let abt = SemanticASTVisitor(ast: ast("""
		var foo = true
		""")).visit()

		let decl = abt.cast(Program.self).declarations[0]
		#expect(decl.syntax.start.start == 0)
		#expect(decl.scope.locals["foo"]!.type.description == "Bool")
	}

	@Test("Does not bind when type decl and expr dont agree") func declConflict() {
		let abt = SemanticASTVisitor(ast: ast("""
		var foo: Bool = 123
		""")).visit()

		#expect(!abt.scope.errors.isEmpty)
		#expect(abt.scope.errors[0].location.description.contains("foo"))
		#expect(abt.scope.errors[0].message.contains("Cannot assign"))
	}

	@Test("Error when trying to assign to wrong type") func badAssign() {
		let abt = SemanticASTVisitor(ast: ast("""
		var foo = 123
		foo = "error"
		""")).visit()

		#expect(!abt.scope.errors.isEmpty)
		#expect(abt.scope.errors[0].location.description.contains("foo"))
		#expect(abt.scope.errors[0].message.contains("Cannot assign"))
	}

	@Test("Errors on undeclared var") func undeclaredVar() throws {
		let abt = SemanticASTVisitor(ast: ast("""
		foo = 123
		""")).visit()

		#expect(!abt.scope.errors.isEmpty)
		#expect(abt.scope.errors[0].location.description.contains("foo"))
		#expect(abt.scope.errors[0].message.contains("Undefined variable"))
	}

	@Test("Infer function return value") func inferFuncReturn() throws {
		let abt = SemanticASTVisitor(ast: ast("""
		func foo() {
			123
		}
		""")).visit()

		#expect(abt.scope.locals["foo"]!.type.description == "Function -> (Int)")
	}

	@Test("Error when function type decl that's not inferred return") func inferFuncBadReturn() throws {
		let abt = SemanticASTVisitor(ast: ast("""
		func foo() -> String {
			123
		}
		""")).visit()

		#expect(!abt.scope.errors.isEmpty)
		#expect(abt.scope.errors[0].location.description.contains("foo"))
		#expect(abt.scope.errors[0].message.contains("Cannot return Int"))
	}

	@Test("Infer parameter type from return val") func inferParamterFromReturnVal() throws {
		let abt = SemanticASTVisitor(ast: ast("""
		func foo(a) -> Int {
			a
		}
		""")).visit()

		#expect(abt.scope.errors.isEmpty)

		#expect(abt.scope.locals["a"] == nil)

		let decl = abt.cast(Program.self).declarations[0]

		let varA = decl.scope.locals["a"]!
		#expect(varA.inferedTypeFrom != nil)
		#expect(varA.type.description == "Int")
		#expect(decl.scope.depth == 1)

		#expect(abt.scope.locals["foo"]!.type.description == "Function -> (Int)")
	}

	@Test("If expression") func ifExpr() {
		let abt = SemanticASTVisitor(ast: ast("""
		var a = if false {
			123
		} else {
			456
		}
		""")).visit()

		#expect(abt.scope.errors.isEmpty)
		
		#expect(abt.scope.locals["a"]?.type.description == "Int")

		let decl = abt.cast(Program.self).declarations[0].cast(VarLetDeclaration.self)
		let expression = decl.expression!.cast(IfExpression.self)
		#expect(expression.type.description == "Int")
	}

	@Test("If expression with unmatched branches") func ifExprUnmatching() {
		let abt = SemanticASTVisitor(ast: ast("""
		var a = if false {
			123
		} else {
			"sup"
		}
		""")).visit()

		#expect(!abt.scope.errors.isEmpty)
		#expect(abt.scope.errors[0].message.contains("must match"))
	}

	@Test("If expression w/out boolean condition") func ifExprNonBool() {
		let abt = SemanticASTVisitor(ast: ast("""
		var a = if "yo" {
			123
		} else {
			4567
		}
		""")).visit()

		#expect(!abt.scope.errors.isEmpty)
		#expect(abt.scope.errors[0].message.contains("must be Bool"))
	}
}
