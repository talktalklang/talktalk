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
	@Test("Fib") func fib() {
		let source = """
		func fib(n) {
			if (n <= 1) { return n; }
			return fib(n - 2) + fib(n - 1);
		}

		var i = 0;
		while i < 30 {
			print(fib(i));
			i = i + 1;
		}
		"""

		let output = TestOutput()
		#expect(VM.run(source: source, output: output) == .ok)
		#expect(output.stdout == """
		0.0
		1.0
		1.0
		2.0
		3.0
		5.0
		8.0
		13.0
		21.0
		34.0
		55.0
		89.0
		144.0
		233.0
		377.0
		610.0
		987.0
		1597.0
		2584.0
		4181.0
		6765.0
		10946.0
		17711.0
		28657.0
		46368.0
		75025.0
		121393.0
		196418.0
		317811.0
		514229.0

		""")
	}

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
				let compiler = Compiler(source: source)
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
