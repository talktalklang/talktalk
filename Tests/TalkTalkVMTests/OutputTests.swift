//
//  OutputTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/2/24.
//

import Testing
import Foundation
import TalkTalkBytecode
import TalkTalkVM

class TestOutput: OutputBuffer {
	var stdout: String = ""
	var stderr: String = ""

	func write(_ data: [Byte], to destination: OutputDestination) throws {
		switch destination {
		case .stdout:
			stdout += String(data: Data(data), encoding: .utf8) ?? "<invalid string>"
		case .stderr:
			stderr += String(data: Data(data), encoding: .utf8) ?? "<invalid string>"
		}
	}
}

struct OutputTests: VMTest {
	@Test("Can capture output") func captureOutput() throws {
		let output = TestOutput()
		_ = try run(
			"""
			print("hello world")
			"""
			, output: output
		)

		#expect(output.stdout == "hello world\n")
	}
}
