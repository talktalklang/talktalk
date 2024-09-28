//
//  CommentStoreTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/14/24.
//

@testable import TalkTalkCore
import Testing

struct CommentStoreTests {
	func attachWithAST(comments: [Token], to string: String) -> (CommentStore, [any Syntax]) {
		let lexer = Lexer(.init(path: "test", text: string), preserveComments: true)

		var parser = Parser(lexer)
		let ast = parser.parse()

		#expect(comments == parser.lexer.comments)

		let store = CommentStore(comments: comments)
		return (store, ast)
	}

	func attach(comments: [Token], to string: String) -> CommentSet {
		let context = FormatterVisitor.Context(kind: .topLevel)
		let (store, ast) = attachWithAST(comments: comments, to: string)

		return store.get(for: ast[0], context: context)
	}

	@Test("Can attach leading (basic)") func leadingBasic() throws {
		let comments = [
			Token(path: "test", kind: .comment, start: 0, length: 18, line: 0, column: 0, lexeme: "// This is leading"),
		]

		let set = attach(comments: comments, to: """
		// This is leading
		func foo() {}
		""")

		#expect(set.leadingComments == [
			comments[0],
		])
	}

	@Test("Can attach trailing (basic)") func trailingBasic() throws {
		let comments = [
			Token(path: "test", kind: .comment, start: 14, length: 19, line: 1, column: 0, lexeme: "// This is trailing"),
		]

		let set = attach(comments: comments, to: """
		func foo() {}
		// This is trailing
		func bar() {}
		""")

		#expect(set.trailingComments == [
			comments[0],
		])
	}

	@Test("Can attach dangling (basic)") func danglingBasic() throws {
		let comments = [
			Token(path: "test", kind: .comment, start: 13, length: 19, line: 1, column: 0, lexeme: "// This is dangling"),
		]

		let (store, ast) = attachWithAST(comments: comments, to: """
		func foo() {
		// This is dangling
		}
		""")

		let block = ast[0].cast(FuncExprSyntax.self).body
		let set = store.get(for: block, context: .init(kind: .topLevel))

		#expect(set.danglingComments == [
			comments[0],
		])
	}

	@Test("Can attach dangling (same line)") func danglingSameLine() throws {
		let comments = [
			Token(path: "test", kind: .comment, start: 12, length: 19, line: 0, column: 12, lexeme: "// This is dangling"),
		]

		let (store, ast) = attachWithAST(comments: comments, to: """
		let a = 123	// This is dangling
		""")

		let literal = ast[0].cast(LetDeclSyntax.self).value!.cast(LiteralExprSyntax.self)
		let set = store.get(for: literal, context: .init(kind: .topLevel))

		#expect(set.danglingComments == [
			comments[0],
		])
	}
}
