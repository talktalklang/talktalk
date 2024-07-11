//
//  tlk.swift
//
//
//  Created by Pat Nakajima on 6/30/24.
//

import ArgumentParser
import Foundation
import TalkTalk
import TalkTalkSyntax

@main
struct TlkCommand: ParsableCommand {
	@Argument(help: "The input to run.")
	var input: String

	@Flag(help: "Print debug info")
	var debug: Bool = false

	@Flag(help: "Print the AST")
	var ast: Bool = false
//
//	@Flag(help: "Just print the tokens") var tokenize: Bool = false

	mutating func run() throws {
		let source = if FileManager.default.fileExists(atPath: input) {
			try String(contentsOfFile: input)
		} else {
			input
		}

		let output = StdoutOutput(isDebug: debug)

		if ast {
			let tree = SyntaxTree.parse(source: source)
			ASTPrinter.print(tree)
			return
		}

		if VM.run(source: source, output: output) == .ok {
			return
		} else {
			throw ExitCode.failure
		}
	}
}
