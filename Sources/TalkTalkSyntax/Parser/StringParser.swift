//
//  StringParser.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/12/24.
//

import Foundation

struct StringParser<S: StringProtocol> {
	enum StringError: Error, LocalizedError {
		case invalidEscapeSequence(Character)

		var errorDescription: String {
			switch self {
			case .invalidEscapeSequence(let character):
				"Invalid escape sequence: \\\(character)"
			}
		}
	}

	let input: S

	var current: String.Index

	static func parse(_ string: S) throws -> String {
		var parser = StringParser(input: string)
		return try parser.parsed()
	}

	init(input: S) {
		self.input = input
		self.current = input.startIndex
	}

	mutating func next() -> Character? {
		if current == input.index(input.endIndex, offsetBy: -2) {
			return nil
		}

		advance()

		return input[current]
	}

	mutating func advance() {
		current = input.index(after: current)
	}

	mutating func parsed() throws -> String {
		if input.count == 2 {
			return ""
		}

		var result = ""

		while let char = next() {
			guard char == "\\" else {
				// If we're not escaping we can just append the character and move on
				result.append(char)
				continue
			}

			// If it was "\" then skip that and see what's next
			guard let char = next() else {
				break
			}

			switch char {
			case "n": result.append("\n")
			case "t": result.append("\t")
			case #"""#: result.append(#"""#)
			case #"\"#: result.append(#"\"#)
			default:
				throw StringError.invalidEscapeSequence(char)
			}
		}

		return result
	}
}
