//
//  AST.swift
//
//
//  Created by Pat Nakajima on 7/11/24.
//
import ArgumentParser
import Foundation
import TalkTalkSyntax

struct AST: AsyncParsableCommand {
	@Argument(help: "The input to run.")
	var input: String

	func run() async throws {
		let source = if FileManager.default.fileExists(atPath: input) {
			try String(contentsOfFile: input)
		} else {
			input
		}

		let tree = try SyntaxTree.parse(source: source)
		ASTPrinter.print(tree)
	}
}
