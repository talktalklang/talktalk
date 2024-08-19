//
//  ModuleCompile.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/8/24.
//

import ArgumentParser
import Foundation
import TalkTalkDriver
import TalkTalkSyntax

struct ModuleCompile: TalkTalkCommand {
	static let configuration = CommandConfiguration(
		commandName: "module",
		abstract: "Compiles the given directory to TalkTalk modules"
	)

	@Argument(help: "The directories to compile.", completion: .directory)
	var directories: [String]

	@Flag(help: "Dump the instructions")
	var dump: Bool = false

	func run() async throws {
		let targetDirectories = directories.map { URL.currentDirectory().appending(path: $0) }
		let stdlib = try await StandardLibrary.compile()
		let driver = Driver(
			directories: targetDirectories,
			analyses: ["Standard": stdlib.analysis],
			modules: ["Standard": stdlib.module]
		)

		if dump {
			for (_, result) in try await driver.compile() {
				for chunk in result.module.chunks {
					chunk.dump(in: result.module)
				}
			}

			return
		}

		try await driver.writeModules()
	}
}
