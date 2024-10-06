//
//  StandardLibraryBootstrapTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/10/24.
//

import Foundation
import Testing

@MainActor
struct StandardLibraryBootstrapTests: StandardLibraryTest {
	@Test("Don't need to it") func basic() async throws {
		let result = try await run("""
		let a = []
		return a.count
		""").get()

		#expect(result == .int(0))
	}
}
