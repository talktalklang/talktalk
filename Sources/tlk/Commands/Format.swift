//
//  Format.swift
//
//
//  Created by Pat Nakajima on 7/11/24.
//
import ArgumentParser
import Foundation
import TalkTalkSyntax

struct Format: AsyncParsableCommand {
	@Argument(help: "The input to format. (beta)")
	var input: String

	func run() async throws {
		let source = if FileManager.default.fileExists(atPath: input) {
			try String(contentsOfFile: input)
		} else {
			input
		}

		let tree = try SyntaxTree.parse(source: source)
		ASTFormatter.print(tree)
	}
}
