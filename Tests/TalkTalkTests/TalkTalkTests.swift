@testable import TalkTalk
import Testing

struct LexerTests {
	@Test("Lexing Basic") func lex() {
		let source = "+"
		var lexer = Lexer(source: source)
		#expect(lexer.collect() == [
			Token(start: source.index(at: 0), length: 1, kind: .plus, line: 1),
			Token(start: source.index(at: 1), length: 0, kind: .eof, line: 1)
		])
	}

	@Test("Lexing multiple") func lex2() {
		let source = "+>="
		var lexer = Lexer(source: source)
		#expect(lexer.collect() == [
			Token(start: source.index(at: 0), length: 1, kind: .plus, line: 1),
			Token(start: source.index(at: 1), length: 2, kind: .greaterEqual, line: 1),
			Token(start: source.index(at: 3), length: 0, kind: .eof, line: 1)
		])

		lexer.rewind()
		let dump = lexer.dump()
		let expected = """
		   1 plus +
		   | greaterEqual >=
		   | eof 

		"""

		#expect(
			dump == expected
		)
	}
}
