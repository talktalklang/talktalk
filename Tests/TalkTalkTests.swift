@testable import TalkTalk
import Testing

@Test("Lexing") func lex() {
	let lexer = Lexer(source: "+")
	#expect(lexer.collect() == [
		Token(start: 0, length: 1, kind: .plus, line: 1),
	])
}
