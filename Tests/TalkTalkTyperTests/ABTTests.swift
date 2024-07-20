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

	@Test("Can get the top level function") func topLevel() {
		let abt = SemanticASTVisitor(ast: ast("""
		let foo = "sup"
		""")).visit()

		#expect(abt.cast(Program.self).decls[0])
	}
}
