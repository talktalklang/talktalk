//
//  Format.swift
//
//
//  Created by Pat Nakajima on 7/11/24.
//
import ArgumentParser
import Foundation
import TalkTalkSyntax

struct Format: TalkTalkCommand {
	@Argument(help: "The input to format.")
	var input: String

	func run() async throws {
		let source = switch try get(input: input) {
		case .path(let string):
			string
		case .stdin:
			fatalError("not yet")
		case .string(let string):
			string
		}

		let formatted = Formatter.format(source)
		print(formatted)
	}
}
