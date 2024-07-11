//
//  Format.swift
//  
//
//  Created by Pat Nakajima on 7/11/24.
//
import Foundation
import ArgumentParser
import TalkTalkSyntax

struct Format: AsyncParsableCommand {
	@Argument(help: "The input to run.")
	var input: String

	func run() async throws {
		let source = if FileManager.default.fileExists(atPath: input) {
			try String(contentsOfFile: input)
		} else {
			input
		}

		let tree = SyntaxTree.parse(source: source)
		ASTFormatter.print(tree)
	}
}
