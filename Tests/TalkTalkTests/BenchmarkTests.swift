//
//  Benchmark.swift
//  
//
//  Created by Pat Nakajima on 7/3/24.
//
@testable import TalkTalk
import Testing
import Foundation

struct BenchmarkTests {
	@Test("Test basics") func basics() {
		let source = """
		var i = 0;
		var s = "here's a string";
		var d = "and another string????????";
		var b = s + d;

		while i < 100 {
			b = b + d;
			i = i + 1;
		}
		"""

		let output = TestOutput()
		let t = ContinuousClock().measure {
			for _ in 0..<25 {
				_ = VM.run(source: source, output: output)
			}
		}

		print("Took \(t) sec.")
		#expect(t < .seconds(10))
	}
}
