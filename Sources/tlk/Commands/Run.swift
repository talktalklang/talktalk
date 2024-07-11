//
//  Run.swift
//  
//
//  Created by Pat Nakajima on 7/11/24.
//
import ArgumentParser
import Foundation
import TalkTalk

struct Run: AsyncParsableCommand {
	@Argument(help: "The input to run. Use `-` for stdin.")
	var input: String

	@Flag(help: "Debug mode")
	var debug: Bool = false

	func run() async throws {
		let source = if FileManager.default.fileExists(atPath: input) {
			try String(contentsOfFile: input)
		} else if input == "-" {
			{
				var source = ""
				while let line = readLine() {
					source += line
				}
				return source
			}()
		} else {
			input
		}

		let output = StdoutOutput(isDebug: debug)

		if VM.run(source: source, output: output) == .ok {
			return
		} else {
			throw ExitCode.failure
		}

	}
}
