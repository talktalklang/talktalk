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
		#expect(decl.binding.locals["foo"]!.type.name == "String")
	}

	@Test("Binds String with var") func varString() {
		let abt = SemanticASTVisitor(ast: ast("""
		var foo = "sup"
		""")).visit()

		let decl = abt.cast(Program.self).declarations[0]
		#expect(decl.syntax.start.start == 0)
		#expect(decl.binding.locals["foo"]!.type.name == "String")
	}

	@Test("Binds Int with let") func letInt() {
		let abt = SemanticASTVisitor(ast: ast("""
		let foo = 123
		""")).visit()

		let decl = abt.cast(Program.self).declarations[0]
		#expect(decl.syntax.start.start == 0)
		#expect(decl.binding.locals["foo"]!.type.name == "Int")
	}

	@Test("Binds String with var") func varInt() {
		let abt = SemanticASTVisitor(ast: ast("""
		var foo = 123
		""")).visit()

		let decl = abt.cast(Program.self).declarations[0]
		#expect(decl.syntax.start.start == 0)
		#expect(decl.binding.locals["foo"]!.type.name == "Int")
	}

	@Test("Binds Bool with let") func letBool() {
		let abt = SemanticASTVisitor(ast: ast("""
		let foo = true
		""")).visit()

		let decl = abt.cast(Program.self).declarations[0]
		#expect(decl.syntax.start.start == 0)
		#expect(decl.binding.locals["foo"]!.type.name == "Bool")
	}

	@Test("Binds String with var") func varBool() {
		let abt = SemanticASTVisitor(ast: ast("""
		var foo = true
		""")).visit()

		let decl = abt.cast(Program.self).declarations[0]
		#expect(decl.syntax.start.start == 0)
		#expect(decl.binding.locals["foo"]!.type.name == "Bool")
	}

	@Test("Does not bind when type decl and expr dont agree") func declConflict() {
		let abt = SemanticASTVisitor(ast: ast("""
		var foo: Bool = 123
		""")).visit()

		#expect(!abt.binding.errors.isEmpty)
		#expect(abt.binding.errors[0].location.description.contains("foo"))
		#expect(abt.binding.errors[0].message.contains("Cannot assign"))
	}
}
