struct Token {
	enum Kind: Equatable {
		// Single character tokens
		case leftParen, rightParen, leftBrace, rightBrace,
		     comma, dot, minus, plus, semicolon, slash, star

		// One or two character tokens
		case bang, bangEqual, equal, equalEqual,
		     greater, greaterEqual, less, lessEqual

		// Literals
		case identifier(String), string(String), number(Double)

		// Keywords
		case and, `class`, `else`, `false`, fun, `for`, `if`, `nil`,
		     or, print, `return`, `super`, `self`, `true`, `var`, `while`

		case eof

		static func match(keyword: String) -> Kind? {
			switch keyword.trimmingCharacters(in: .whitespacesAndNewlines) {
			case "and": .and
			case "class": .class
			case "else": .else
			case "false": .false
			case "for": .for
			case "fun": .fun
			case "if": .if
			case "nil": .nil
			case "or": .or
			case "print": .print
			case "return": .return
			case "super": .super
			case "self": .self
			case "true": .true
			case "var": .var
			case "while": .while
			default: nil
			}
		}
	}

	let kind: Kind
	let lexeme: String
	let line: Int

	var description: String {
		"\(kind) \(lexeme)"
	}
}

struct Scanner {
	var source: String

	var tokens: [Token] = []
	var start = 0
	var current = 0
	var line = 1

	init(source: String) {
		self.source = source
	}

	mutating func scanTokens() -> [Token] {
		while !isAtEnd {
			start = current
			scanToken()
		}

		tokens.append(Token(kind: .eof, lexeme: "", line: line))

		return tokens
	}

	mutating func scanToken() {
		let char = advance()
		switch char {
		case "(": addToken(.leftParen)
		case ")": addToken(.rightParen)
		case "{": addToken(.leftBrace)
		case "}": addToken(.rightBrace)
		case ",": addToken(.comma)
		case ".": addToken(.dot)
		case "-": addToken(.minus)
		case "+": addToken(.plus)
		case ";": addToken(.semicolon)
		case "*": addToken(.star)
		case "!": addToken(matching(char: "=") ? .bangEqual : .bang)
		case "=": addToken(matching(char: "=") ? .equalEqual : .equal)
		case "<": addToken(matching(char: "=") ? .lessEqual : .less)
		case ">": addToken(matching(char: "=") ? .greaterEqual : .greater)
		case "/":
			if matching(char: "/") {
				while peek() != "\n" {
					advance()
				}
			} else {
				addToken(.slash)
			}
		case #"""#: string()
		case " ", "\r", "\t":
			() // Ignore whitespace
		case "\n":
			line += 1
		case _ where char.isNumber:
			number()
		case _ where char.isLetter || char == "_":
			identifier()
		default:
			Swlox.error("Unexpected character: \(char)", line: line)
		}
	}

	mutating func identifier() {
		while peek().isLetter || peek().isNumber || peek() == "_" {
			advance()
		}

		let text = String(source[index(at: start) ..< index(at: current)])

		if let keyword = Token.Kind.match(keyword: text) {
			addToken(keyword)
		} else {
			addToken(.identifier(text))
		}
	}

	mutating func string() {
		while peek() != #"""#, !isAtEnd {
			if peek() == "\n" { line += 1 }
			advance()
		}

		if isAtEnd {
			Swlox.error("Unterminated string", line: line)
			return
		}

		// The closing "\""
		advance()

		// Trim the surrounding quotes
		addToken(.string(String(source[index(at: start + 1) ..< index(at: current - 1)])))
	}

	mutating func number() {
		while peek().isNumber {
			advance()
		}

		if peek() == ".", peekNext().isNumber {
			advance() // consume the "."

			while peek().isNumber {
				advance()
			}
		}

		if let literal = Double(String(source[index(at: start) ..< index(at: current)])) {
			addToken(.number(literal))
		} else {
			Swlox.error("Invalid number", line: line)
		}
	}

	mutating func matching(char: Substring.Element) -> Bool {
		if isAtEnd {
			return false
		}

		if peek() != char {
			return false
		}

		current += 1
		return true
	}

	func peek() -> Substring.Element {
		if isAtEnd {
			return "\0"
		}

		return source[index(at: current)]
	}

	func peekNext() -> Substring.Element {
		if current + 1 >= source.count {
			return "\0"
		}

		return source[index(at: current + 1)]
	}

	@discardableResult mutating func advance() -> Substring.Element {
		defer {
			current += 1
		}
		return source[index(at: current)]
	}

	mutating func addToken(_ kind: Token.Kind) {
		let text = String(source[index(at: start) ..< index(at: current)])
		tokens.append(.init(kind: kind, lexeme: text, line: line))
	}

	func index(at: Int) -> String.Index {
		return source.index(source.startIndex, offsetBy: at)
	}

	var isAtEnd: Bool {
		return current >= source.count
	}
}
