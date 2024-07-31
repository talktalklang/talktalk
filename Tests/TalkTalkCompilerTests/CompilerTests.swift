//
//  CompilerTests.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//
import Foundation
import TalkTalkAnalysis
import TalkTalkCompiler
import Testing

struct CompilerTests {
	@Test("Compiles literals") func literals() {
		#expect(Compiler("1").run() == .int(1))
		#expect(Compiler("(2)").run() == .int(2))
	}

	@Test("Compiles add") func add() {
		#expect(Compiler("1 + 2").run() == .int(3))
	}

	@Test("Compiles def") func def() {
		#expect(Compiler("""
		abc = 1 + 2
		abc
		""").run() == .int(3))
	}

	@Test("Compiles multiple") func multiple() {
		#expect(Compiler("""
		a = 1
		b = 2
		a + b
		""").run() == .int(3))
	}

	@Test("Compiles if") func ifEval() {
		#expect(Compiler("""
		if false {
			a = 1
		} else {
			a = 2
		}
		a
		""").run() == .int(2))
	}

	@Test("Evaluates while") func whileEval() {
		#expect(Compiler("""
		a = 0
		while a != 4 {
			a = a + 1
		}
		a
		""").run() == .int(4))
	}

	@Test("Compiles functions") func functions() {
		#expect(Compiler("""
		addtwo = func(x) {
			x + 2
		}
		addtwo(2)
		""").run() == .int(4))
	}

	@Test("Compiles counter") func counter() {
		#expect(Compiler("""
		makeCounter = func() {
			count = 0
			func() {
				count = count + 1
				count
			}
		}

		counter = makeCounter()
		counter()
		counter()
		""").run() == .int(2))
	}

	@Test("Compiles nested scopes") func nestedScopes() {
		#expect(Compiler("""
		addthis = func(x) {
			func(y) {
				x + y
			}
		}

		addfour = addthis(4)
		addfour(2)
		""").run() == .int(6))
	}

	@Test("Works with printf") func printTest() {
		let out = captureOutput {
			Compiler("printf(1)").run()
		}

		#expect(out.output == "1\n")
	}

	@Test("Compiles Struct properties") func structs() {
		#expect(Compiler("""
		struct Foo {
			let age: i32
		}

		foo = Foo(age: 123)
		foo.age + 4
		""").run() == .int(127))
	}

	@Test("Compiles Struct methods") func methods() {
		#expect(Compiler("""
		struct Foo {
			let age: i32

			func add() {
				age + 4
			}
		}

		foo = Foo(age: 123)
		foo.add()
		""").run() == .int(127))
	}

	// helpers

	public func captureOutput<R>(block: () -> R) -> (output: String, error: String, result: R) {
		// Create pipes for capturing stdout and stderr
		var stdoutPipe = [Int32](repeating: 0, count: 2)
		var stderrPipe = [Int32](repeating: 0, count: 2)
		pipe(&stdoutPipe)
		pipe(&stderrPipe)

		// Save original stdout and stderr
		let originalStdout = dup(STDOUT_FILENO)
		let originalStderr = dup(STDERR_FILENO)

		// Redirect stdout and stderr to the pipes
		dup2(stdoutPipe[1], STDOUT_FILENO)
		dup2(stderrPipe[1], STDERR_FILENO)
		close(stdoutPipe[1])
		close(stderrPipe[1])

		// Execute the block and capture the result
		let result = block()

		// Restore original stdout and stderr
		dup2(originalStdout, STDOUT_FILENO)
		dup2(originalStderr, STDERR_FILENO)
		close(originalStdout)
		close(originalStderr)

		// Read captured output
		let stdoutData = readData(from: stdoutPipe[0])
		let stderrData = readData(from: stderrPipe[0])

		// Convert data to strings
		let stdoutOutput = String(data: stdoutData, encoding: .utf8) ?? ""
		let stderrOutput = String(data: stderrData, encoding: .utf8) ?? ""

		return (output: stdoutOutput, error: stderrOutput, result: result)
	}

	private func readData(from fd: Int32) -> Data {
		var data = Data()
		let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 1024)
		defer { buffer.deallocate() }

		while true {
			let count = read(fd, buffer, 1024)
			if count <= 0 {
				break
			}
			data.append(buffer, count: count)
		}

		return data
	}
}
