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
		let filename: String
		let source: String

		if FileManager.default.fileExists(atPath: input) {
			filename = input
			source = try String(contentsOfFile: input)
		} else {
			filename = "<stdin>"
			source = input
		}

		let tree = try SyntaxTree.parse(filename: filename, source: source)
		ASTPrinter.print(tree)
	}
}
