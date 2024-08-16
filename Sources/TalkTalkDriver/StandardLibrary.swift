//
//  StandardLibrary.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/14/24.
//

import TalkTalkCore
import TalkTalkCompiler

public struct StandardLibrary {
	public static func compile() async throws -> CompilationResult {
		let driver = Driver(
			directories: [Library.standardLibraryURL],
			analyses: [:],
			modules: [:]
		)
		
		return try await driver.compile(mode: .module)["Standard"]!
	}
}