@testable import TalkTalkSyntax
import Testing

struct TalkTalkLexerTests {
	@Test("Int") func int() {
		var lexer = TalkTalkLexer("1")
		let tokens = lexer.collect()

		#expect(tokens.map(\.kind) == [
			.int,
			.eof,
		])

		#expect(tokens.map(\.line) == [
			1,
			1,
		])
	}

	@Test("Symbols and ints and parens") func symbolsAndInts() async throws {
		var lexer = TalkTalkLexer("10 ^ 20")
		let tokens = lexer.collect()

		#expect(tokens.map(\.kind) == [
			.int,
			.symbol,
			.int,
			.eof,
		])

		#expect(tokens.map(\.column) == [
			1,
			4,
			6,
			8,
		])
	}

	@Test("Floats") func floats() async throws {
		var lexer = TalkTalkLexer("1.23")
		let token = lexer.collect()[0]
		#expect(token.kind == .float)
		#expect(token.lexeme == "1.23")
	}

	@Test("Identifier") func identifier() async throws {
		var lexer = TalkTalkLexer("foo")
		let token = lexer.collect()[0]
		#expect(token.kind == .identifier)
		#expect(token.lexeme == "foo")
	}

	@Test("eof") func eof() async throws {
		var lexer = TalkTalkLexer("()")
		let tokens = lexer.collect()

		#expect(tokens[0].kind == .leftParen)
		#expect(tokens[0].lexeme == "(")

		#expect(tokens[1].kind == .rightParen)
		#expect(tokens[1].lexeme == ")")

		#expect(tokens[2].kind == .eof)
		#expect(tokens[2].lexeme == "EOF")
	}

	@Test("equals") func equals() throws {
		var lexer = TalkTalkLexer("foo = 123")
		let tokens = lexer.collect()

		#expect(tokens.map(\.kind) == [
			.identifier,
			.equals,
			.int,
			.eof
		])
	}

	@Test("anon func") func anonfunction() throws {
		var lexer = TalkTalkLexer("func(x, y) { 10 }")
		let tokens = lexer.collect()

		#expect(tokens.map(\.kind) == [
			.func,
			.leftParen,
			.identifier,
			.comma,
			.identifier,
			.rightParen,
			.leftBrace,
			.int,
			.rightBrace,
			.eof
		])
	}

	@Test("func") func function() async throws {
		var lexer = TalkTalkLexer("""
		func foo() {
			10
		}
		""")
		let tokens = lexer.collect()

		#expect(tokens.map(\.kind) == [
			.func,
			.identifier,
			.leftParen,
			.rightParen,
			.leftBrace,
			.newline,
			.int,
			.newline,
			.rightBrace,
			.eof
		])

		#expect(tokens.map(\.line) == [
			1,
			1,
			1,
			1,
			1,
			2,
			2,
			3,
			3,
			3
		])
	}

	@Test("while") func whilekeyword() {
		var lexer = TalkTalkLexer("while { }")
		let tokens = lexer.collect()

		#expect(tokens.map(\.kind) == [
			.while,
			.leftBrace,
			.rightBrace,
			.eof
		])
	}

	@Test("newline collapsing") func newline() async throws {
		var lexer = TalkTalkLexer("""


		""")
		let tokens = lexer.collect()
		#expect(tokens.count == 2)
		#expect(tokens[0].kind == .newline)
		#expect(tokens[1].kind == .eof)
	}
}
