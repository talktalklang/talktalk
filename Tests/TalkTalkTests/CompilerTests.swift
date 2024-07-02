//
//  CompilerTests.swift
//  
//
//  Created by Pat Nakajima on 7/1/24.
//
@testable import TalkTalk
import Testing

class TestOutput: OutputCollector {
	func print(_ output: String) {
		out.append(output)
		out.append("\n")
	}

	func print(_ output: String, terminator: String) {
		out.append(output)
		out.append(terminator)
	}

	var out: [String] = []
}

struct CompilerTests {
	@Test("Addition") func addition() {
		let output = TestOutput()
		let source = "1 + -2"
		var compiler = Compiler(source: source)
		compiler.compile()

		var vm = VM(output: output)
		let result = vm.run(chunk: &compiler.compilingChunk)

		#expect(result == .ok)
		#expect(output.out[output.out.count - 2].trimmingCharacters(in: .whitespaces) == "number(-1.0)")
	}

	@Test("Subtraction") func subtraction() {
		let output = TestOutput()
		let source = "123 - 3"
		var compiler = Compiler(source: source)
		compiler.compile()

		var vm = VM(output: output)
		let result = vm.run(chunk: &compiler.compilingChunk)

		#expect(result == .ok)
		#expect(output.out[output.out.count - 2].trimmingCharacters(in: .whitespaces) == "number(120.0)")
	}

	@Test("Multiplication") func multiplication() {
		let output = TestOutput()
		let source = "5 * 5"
		var compiler = Compiler(source: source)
		compiler.compile()

		var vm = VM(output: output)
		let result = vm.run(chunk: &compiler.compilingChunk)

		#expect(result == .ok)
		#expect(output.out[output.out.count - 2].trimmingCharacters(in: .whitespaces) == "number(25.0)")
	}

	@Test("Division") func dividing() {
		let output = TestOutput()
		let source = "25 / 5"
		var compiler = Compiler(source: source)
		compiler.compile()

		var vm = VM(output: output)
		let result = vm.run(chunk: &compiler.compilingChunk)

		#expect(result == .ok)
		#expect(output.out[output.out.count - 2].trimmingCharacters(in: .whitespaces) == "number(5.0)")
	}

	@Test("Basic (with concurrency)") func basic() async {
		let count = await withTaskGroup(of: Void.self) { group in
			group.addTask {
				for _ in 0..<100 {
					let source = "1 + -2"
					var compiler = Compiler(source: source)
					compiler.compile()


					var vm = VM()
					let result = vm.run(chunk: &compiler.compilingChunk)
					#expect(result == .ok)
				}
			}

			var count = 0
			for await _ in group {
				count += 1
			}

			return count
		}

		#expect(count == 1)
	}
}
