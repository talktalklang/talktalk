//
//  tlk.swift
//
//
//  Created by Pat Nakajima on 6/30/24.
//

import ArgumentParser
import Foundation
import TalkTalk

@main
struct TlkCommand: ParsableCommand {
	@Argument(help: "The input to run.")
	var input: String

	@Argument(help: "Print debug info")
	var isDebug: Bool = false
//
//	@Flag(help: "Just print the tokens") var tokenize: Bool = false

	mutating func run() throws {
		let source = if FileManager.default.fileExists(atPath: input) {
			try String(contentsOfFile: input)
		} else {
			input
		}

		var output = StdoutOutput(isDebug: isDebug)

		if VM.run(source: source, output: output) == .ok {
			return
		} else {
			throw ExitCode.failure
		}
	}
}
