//
//  Benchmark.swift
//
//
//  Created by Pat Nakajima on 7/3/24.
//
import Foundation
@testable import TalkTalk
import Testing

struct BenchmarkTests {
	@Test("Test compile time") func compile() {
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

		let t = ContinuousClock().measure {
			for _ in 0 ..< 5000 {
				var compiler = Compiler(source: source)
				try! compiler.compile()
			}
		}

		print("Took \(t) sec.")
		#expect(t < .seconds(10))
	}

	@Test("Test execution time") func basics() {
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
			for _ in 0 ..< 50 {
				_ = VM.run(source: source, output: output)
			}
		}

		print("Took \(t) sec.")
		#expect(t < .seconds(5))
	}
}
