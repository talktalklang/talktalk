//
//  CompilerTests.swift
//
//
//  Created by Pat Nakajima on 7/1/24.
//
@testable import TalkTalk
import Testing

class TestOutput: OutputCollector {
	func print(_ output: String, terminator: String) {
		stdout.append(output)
		stdout.append(terminator)
	}

	func debug(_ output: String, terminator: String) {
		debugOut.append(output)
		debugOut.append(terminator)
	}

	var stdout: String = ""
	var debugOut: String = ""
}

struct CompilerTests {
	@Test("Addition") func addition() {
		let output = TestOutput()
		#expect(VM.run(source: "print 1 + -2;", output: output) == .ok)

		print(output.debugOut)

		#expect(output.stdout == "-1.0\n")
	}

	@Test("Subtraction") func subtraction() {
		let output = TestOutput()
		#expect(VM.run(source: "print 123 - 3;", output: output) == .ok)
		#expect(output.stdout == "120.0\n")
	}

	@Test("Multiplication") func multiplication() {
		let output = TestOutput()
		#expect(VM.run(source: "print 5 * 5;", output: output) == .ok)
		#expect(output.stdout == "25.0\n")
	}

	@Test("Division") func dividing() {
		let output = TestOutput()
		#expect(VM.run(source: "print 25 / 5;", output: output) == .ok)
		#expect(output.stdout == "5.0\n")
	}

	@Test("Basic (with concurrency)") func basic() async {
		let count = await withTaskGroup(of: Void.self) { group in
			group.addTask {
				for _ in 0 ..< 100 {
					let source = "print 1 + -2;"
					var compiler = Compiler(source: source)
					try! compiler.compile()

					let output = TestOutput()
					var vm = VM(output: output)
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

	@Test("Bools") func bools() {
		var output = TestOutput()
		#expect(VM.run(source: "print true;", output: output) == .ok)
		#expect(output.stdout == "true\n")

		output = TestOutput()
		#expect(VM.run(source: "print false;", output: output) == .ok)
		#expect(output.stdout == "false\n")
	}

	@Test("Negation") func negation() {
		let output = TestOutput()
		#expect(VM.run(source: "print !false;", output: output) == .ok)
		#expect(output.stdout == "true\n")
	}

	@Test("Equality") func equality() {
		let output = TestOutput()
		#expect(VM.run(source: "print 2 == 2;", output: output) == .ok)
		#expect(output.stdout == "true\n")
	}

	@Test("Not equality") func notEquality() {
		let output = TestOutput()
		#expect(VM.run(source: "print 1 != 2;", output: output) == .ok)
		#expect(output.stdout == "true\n")
	}

	@Test("nil") func nill() {
		let output = TestOutput()
		#expect(VM.run(source: "print nil;", output: output) == .ok)
		#expect(output.stdout == "nil\n")
	}

	@Test("Strings") func string() {
		let output = TestOutput()
		let source = """
		print "hello world";
		"""
		var compiler = Compiler(source: source)
		try! compiler.compile()

		var vm = VM(output: output)
		let result = vm.run(chunk: &compiler.compilingChunk)

		#expect(result == .ok)
		#expect(output.stdout == "hello world\n")
	}

	@Test("Global variables") func globals() {
		let output = TestOutput()
		let source = """
		var greeting = "hello world";
		print greeting;
		"""

		#expect(VM.run(source: source, output: output) == .ok)
		#expect(output.stdout == "hello world\n")
	}

	@Test("Global variable reassignment") func globalReassignment() {
		let output = TestOutput()
		let source = """
		var greeting = "hello world";
		greeting = greeting + " SUP";
		print greeting;
		"""

		#expect(VM.run(source: source, output: output) == .ok)
		#expect(output.stdout == "hello world SUP\n")
	}

	@Test("Assignment precedence") func assignmentPrecedence() {
		let output = TestOutput()
		let source = """
		var a = 1;
		var b = 1;
		var c = 1;
		var d = 1;

		print a * b = c + d;
		"""

		#expect(VM.run(source: source, output: output) == .compileError)
		#expect(output.stdout.contains("Syntax Error"))
	}

	@Test("Local vars") func locals() {
		let output = TestOutput()
		let source = """
		{
			var a = "world";

			{
				var a = "hello";
				print a;
			}

			print a;
		}
		"""

		#expect(VM.run(source: source, output: output) == .ok)
		#expect(output.stdout == "hello\nworld\n")
	}

	@Test("Local variables with numbers") func localsWithNumbers() {
		let output = TestOutput()
		let source = """
		{
			var a = 1;

			{
				var b = 2;
				print a + b;
			}

			print a + 3;
		}
		"""

		#expect(VM.run(source: source, output: output) == .ok)
		print(output.debugOut)
		#expect(output.stdout == "3.0\n4.0\n")
	}
}
