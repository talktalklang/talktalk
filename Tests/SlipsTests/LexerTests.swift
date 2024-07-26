@testable import Slips
import Testing

struct LexerTests {
	@Test("Int") func int() {
		var lexer = Lexer("1")
		let tokens = lexer.collect()

		#expect(tokens.map(\.kind) == [
			.int,
			.eof,
		])
	}

	@Test("Symbols and ints and parens") func symbolsAndInts() async throws {
		var lexer = Lexer("(<= 10 20)")
		let tokens = lexer.collect()

		#expect(tokens.map(\.kind) == [
			.leftParen,
			.symbol,
			.int,
			.int,
			.rightParen,
			.eof,
		])
	}

	@Test("Floats") func floats() async throws {
		var lexer = Lexer("(1.23)")
		let token = lexer.collect()[1]
		#expect(token.kind == .float)
		#expect(token.lexeme == "1.23")
	}

	@Test("Identifier") func identifier() async throws {
		var lexer = Lexer("(foo)")
		let token = lexer.collect()[1]
		#expect(token.kind == .identifier)
		#expect(token.lexeme == "foo")
	}

	@Test("def") func def() async throws {
		var lexer = Lexer("(def foo 1.23)")
		let token = lexer.collect()[1]
		#expect(token.kind == .def)
		#expect(token.lexeme == "def")
	}
}
