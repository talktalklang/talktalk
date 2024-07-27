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

	@Test("eof") func eof() async throws {
		var lexer = Lexer("()")
		let tokens = lexer.collect()

		#expect(tokens[0].kind == .leftParen)
		#expect(tokens[0].lexeme == "(")

		#expect(tokens[1].kind == .rightParen)
		#expect(tokens[1].lexeme == ")")

		#expect(tokens[2].kind == .eof)
		#expect(tokens[2].lexeme == "EOF")
	}

	@Test("def") func def() async throws {
		var lexer = Lexer("(def foo 1.23)")
		let token = lexer.collect()[1]
		#expect(token.kind == .def)
		#expect(token.lexeme == "def")
	}

	@Test("newline collapsing") func newline() async throws {
		var lexer = Lexer("""
		
		
		""")
		let tokens = lexer.collect()
		#expect(tokens.count == 2)
		#expect(tokens[0].kind == .newline)
	}
}
