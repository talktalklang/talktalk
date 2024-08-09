//
//  DiagnosticTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/6/24.
//
import Testing
import TalkTalkLSP

@MainActor
struct DiagnosticTests {
	@Test("Gets diagnostics") func gets() {
		_ = """
		1 + a
		"""

		// Um, TODO.
	}
}
