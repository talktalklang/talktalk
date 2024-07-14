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

	@Test("Can find position from col/line") func position() {
		let source = """
		123456789
		123456789
		123456789
		"""

		#expect(source.position(line: 1, column: 1) == 0)
		#expect(source.position(line: 2, column: 1) == 10)
	}
}