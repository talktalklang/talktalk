//
//  IntTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/14/24.
//

import Testing
import TalkTalkVM

struct IntTests: StandardLibraryTest {
	@Test("Basic") func basic() async throws {
		let result = try await run("return 123").get()
		#expect(result == .int(123))
	}
}
