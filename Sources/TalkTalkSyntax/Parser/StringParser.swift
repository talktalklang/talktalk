//
//  StringParser.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/12/24.
//

import Foundation

struct StringParser<S: StringProtocol> {
	enum Context {
		case normal, beforeInterpolation, afterInterpolation
	}

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
	let context: Context
	var endOffset: Int = 0

	static func parse(_ string: S, context: Context) throws -> String {
		var parser = StringParser(input: string, context: context)
		return try parser.parsed()
	}

	init(input: S, context: Context) {
		self.input = input
		self.current = input.startIndex
		self.context = context

		switch context {
		case .normal:
			// Skip the opening '"'
			advance()
			// Skip the ending '"'
			endOffset = -1
		case .beforeInterpolation:
			// Skip the opening '"'
			advance()
			// but don't look for '"' at the end
			endOffset = 0
		case .afterInterpolation:
			// Don't bother skipping opening '"'
			endOffset = -1
		}
	}

	mutating func next() -> Character? {
		if current == input.index(input.endIndex, offsetBy: endOffset) {
			return nil
		}

		defer {
			advance()
		}

		return input[current]
	}

	mutating func advance() {
		current = input.index(after: current)
	}

	mutating internal func parsed() throws -> String {
		if input.count == 2 - endOffset {
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
