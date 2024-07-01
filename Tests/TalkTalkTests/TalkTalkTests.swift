@testable import TalkTalk
import Testing

struct LexerTests {
	@Test("Lexing Basic") func lex() {
		let source = "+"
		var lexer = Lexer(source: source)
		#expect(lexer.collect() == [
			Token(start: source.index(at: 0), length: 1, kind: .plus, line: 1),
			Token(start: source.endIndex, length: 0, kind: .eof, line: 1)
		])
	}

	@Test("Lexing multiple") func lex2() {
		let source = "+ >="
		var lexer = Lexer(source: source)
		#expect(lexer.collect() == [
			Token(start: source.index(at: 0), length: 1, kind: .plus, line: 1),
			Token(start: source.index(at: 2), length: 2, kind: .greaterEqual, line: 1),
			Token(start: source.endIndex, length: 0, kind: .eof, line: 1)
		])

		lexer.rewind()
		let dump = lexer.dump()
		let expected = """
		   1 [0] plus +
		   | [2] greaterEqual >=
		   | [4] eof\(" " /* Adding this as interpolation so it doesn't get stripped */ )

		"""

		#expect(
			dump == expected
		)
	}

	@Test("Comments") func comments() {
		let source = """
		// This is a comment
		+ >=
		"""

		var lexer = Lexer(source: source)
		#expect(lexer.collect() == [
			Token(start: source.index(at: 21), length: 1, kind: .plus, line: 2),
			Token(start: source.index(at: 23), length: 2, kind: .greaterEqual, line: 2),
			Token(start: source.endIndex, length: 0, kind: .eof, line: 2)
		])
	}

	@Test("String literal") func stringLiteral() {
		let source = """
		"hello world"
		"""

		var lexer = Lexer(source: source)

		let tokens = lexer.collect()

		#expect(tokens == [
			Token(start: source.index(at: 0), length: 13, kind: .string, line: 1),
			Token(start: source.endIndex, length: 0, kind: .eof, line: 1)
		])
	}

	@Test("Number literal") func numberLiteral() {
		let source = """
		1 1.2
		"""

		var lexer = Lexer(source: source)

		let tokens = lexer.collect()

		#expect(tokens == [
			Token(start: source.index(at: 0), length: 1, kind: .number, line: 1),
			Token(start: source.index(at: 2), length: 3, kind: .number, line: 1),
			Token(start: source.endIndex, length: 0, kind: .eof, line: 1)
		])
	}

	@Test("Identifier") func identifier() {
		let source = """
		variable
		"""

		var lexer = Lexer(source: source)
		#expect(lexer.collect() == [
			Token(start: source.index(at: 0), length: 8, kind: .identifier, line: 1),
			Token(start: source.endIndex, length: 0, kind: .eof, line: 1)
		])
	}

	@Test("Identifier that matches the start of a keyword") func identifierNotClashing() {
		let source = """
		v
		"""

		var lexer = Lexer(source: source)
		#expect(lexer.collect() == [
			Token(start: source.index(at: 0), length: 1, kind: .identifier, line: 1),
			Token(start: source.endIndex, length: 0, kind: .eof, line: 1)
		])
	}

	@Test("Keywords") func keyword() {
		let source = """
		var
		"""

		var lexer = Lexer(source: source)
		#expect(lexer.collect() == [
			Token(start: source.index(at: 0), length: 3, kind: .var, line: 1),
			Token(start: source.endIndex, length: 0, kind: .eof, line: 1)
		])
	}
}
