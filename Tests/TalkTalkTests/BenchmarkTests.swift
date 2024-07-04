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
		var i = 100;
		var s = "here's a string";
		var d = "and another string????????";
		var b = s + d;

		while i > 0 {
			b = b + d;
			i = i + 1;
		}
		"""

		let t = ContinuousClock().measure {
			for _ in 0..<10_000 {
				var compiler = Compiler(source: source)
				try! compiler.compile()
			}
		}

		print("Took \(t) sec.")
	}
}
