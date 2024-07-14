//
//  StringExtensionTests.swift
//
//
//  Created by Pat Nakajima on 7/14/24.
//
@testable import TalkTalkTyper
import Testing

struct StringExtensionTests {
	@Test("can find inline offset") func inlineOffset() {
		let source = """
		123456789
		123456789
		123456789
		"""

		#expect(source.inlineOffset(for: 13, line: 2) == 4)
	}
}
