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

	func run() async throws {
		let targetDirectories = directories.map { URL.currentDirectory().appending(path: $0) }
		let driver = Driver(directories: targetDirectories)
		try await driver.writeModules()
	}
}
