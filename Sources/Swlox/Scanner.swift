struct Token {

}

struct Scanner {
	let source: String

	init(source: String) {
		self.source = source
	}

	func scanTokens() -> [Token] {
		[]
	}
}
