//
//  Check.swift
//
//
//  Created by Pat Nakajima on 7/11/24.
//
import ArgumentParser
import Foundation
import TalkTalkTyper

struct Check: AsyncParsableCommand {
	@Argument(help: "The input to format. (beta)")
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

		let checker = try Typer(filename: filename, source: source)
		let results = checker.check()

		if results.errors.isEmpty {
			print("OK")
		} else {
			for error in results.errors {
				error.report(in: source)
			}

			throw ExitCode(1)
		}
	}
}
