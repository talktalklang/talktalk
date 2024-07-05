//
//  tlk.swift
//
//
//  Created by Pat Nakajima on 6/30/24.
//

import ArgumentParser
@testable import TalkTalk
import Foundation

@main
struct TlkCommand: ParsableCommand {
	@Argument(help: "The input to run.")
	var input: String
//
//	@Flag(help: "Just print the tokens") var tokenize: Bool = false

	mutating func run() throws {
		let source = if FileManager.default.fileExists(atPath: input) {
			try String(contentsOfFile: input)
		} else {
			input
		}

		if VM.run(source: source, output: StdoutOutput()) == .ok {
			return
		} else {
			throw ExitCode.failure
		}
	}
}
