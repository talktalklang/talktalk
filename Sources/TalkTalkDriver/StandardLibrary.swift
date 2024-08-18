//
//  StandardLibrary.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/14/24.
//

import TalkTalkCompiler
import TalkTalkCore

public enum StandardLibrary {
	public static func compile(allowErrors: Bool = false) async throws -> CompilationResult {
		let driver = Driver(
			directories: [Library.standardLibraryURL],
			analyses: [:],
			modules: [:]
		)

		return try await driver.compile(mode: .module, allowErrors: allowErrors)["Standard"]!
	}
}
