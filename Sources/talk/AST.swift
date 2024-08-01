//
//  AST.swift
//
//
//  Created by Pat Nakajima on 7/11/24.
//
import ArgumentParser
import Foundation
import TalkTalkSyntax

struct AST: TalkTalkCommand {
	@Argument(help: "The input to run.")
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

		let parsed = Parser.parse(source)
		let formatted = try ASTPrinter.format(parsed)
		print(formatted)
	}
}
