import Testing
@testable import TalkTalk

@Test("Lexing") func lex() {
	let lexer = Lexer(source: "+")
	#expect(lexer.collect() == [
		Token(start: 0, length: 1, kind: .plus, line: 1)
	])
}
