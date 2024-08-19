//
//  Run.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/17/24.
//

import ArgumentParser
import Foundation
import TalkTalkAnalysis
import TalkTalkCompiler
import TalkTalkDriver
import TalkTalkSyntax
import TalkTalkVM

struct Run: TalkTalkCommand {
	static let configuration = CommandConfiguration(
		abstract: "Compile and run a TalkTalk program"
	)

	@Argument(help: "The program file to run.", completion: .file(extensions: [".tlk"]))
	var input: String

	func run() async throws {
		let source = try get(input: input)
		let stdlib = try await StandardLibrary.compile()

		let analyzed = try ModuleAnalyzer(
			name: source.filename,
			files: [
				ParsedSourceFile(path: source.path, syntax: Parser.parse(source))
			],
			moduleEnvironment: [:],
			importedModules: [stdlib.analysis]
		).analyze()

		if try !analyzed.collectErrors().isEmpty {
			throw ExitCode.validationFailure
		}

		let module = try ModuleCompiler(
			name: source.filename,
			analysisModule: analyzed,
			moduleEnvironment: ["Standard": stdlib.module]
		).compile(mode: .executable)

		if let error = try VirtualMachine.run(module: module).error() {
			throw ExitCode.failure
		} else {
			throw ExitCode.success
		}
	}
}
