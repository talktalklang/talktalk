//
//  FakeHeapTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/11/24.
//

import Testing

struct FakeHeapTests: StandardLibraryTest {
	@Test("Can allocate") func create() async throws {
		let result = try await run("""
		pointer = _allocate(4)
		""").get()

		#expect(result == .pointer(0, 0))
	}
}
