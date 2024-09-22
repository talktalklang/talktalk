//
//  Run.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/17/24.
//

import ArgumentParser
import TalkTalkAnalysis
import TalkTalkCompiler
import TalkTalkDriver
import TalkTalkSyntax
import TalkTalkVM

struct Run: TalkTalkCommand {
	static let configuration = CommandConfiguration(
		abstract: "Compile and run a TalkTalk program"
	)

	@ArgumentParser.Argument(help: "The program file to run.", completion: .file(extensions: [".talk"]))
	var input: String

	func run() async throws {
		let source = try get(input: input)

		let analyzed = try ModuleAnalyzer(
			name: source.filename,
			files: [
				ParsedSourceFile(path: source.path, syntax: Parser.parse(source)),
			],
			moduleEnvironment: [:],
			importedModules: []
		).analyze()

		if try !analyzed.collectErrors().isEmpty {
			throw ExitCode.validationFailure
		}

		let module = try ModuleCompiler(
			name: source.filename,
			analysisModule: analyzed,
			moduleEnvironment: [:]
		).compile(mode: .executable)

		if case .error = try VirtualMachine.run(module: module) {
			throw ExitCode.failure
		} else {
			throw ExitCode.success
		}
	}
}
