//
//  VMEndToEndTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/2/24.
//

import Foundation
import TalkTalkAnalysis
import TalkTalkBytecode
import TalkTalkCompiler
import TalkTalkSyntax
import TalkTalkVM
import Testing

actor VMEndToEndTests {
	func compile(_ strings: String...) throws -> Module {
		try compile(strings)
	}

	func compile(_ strings: [String]) throws -> Module {
		let analysisModule = try ModuleAnalyzer(name: "E2E", files: strings.map { .tmp($0) }, moduleEnvironment: [:]).analyze()
		let compiler = ModuleCompiler(name: "E2E", analysisModule: analysisModule)
		return try compiler.compile(mode: .executable)
	}

	func compile(
		name: String,
		_ files: [ParsedSourceFile],
		analysisEnvironment: [String: AnalysisModule] = [:],
		moduleEnvironment: [String: Module] = [:]
	) -> (Module, AnalysisModule) {
		let analysis = moduleEnvironment.reduce(into: [:]) { res, tup in res[tup.key] = analysisEnvironment[tup.key] }
		let analyzed = try! ModuleAnalyzer(name: name, files: files, moduleEnvironment: analysis).analyze()
		let module = try! ModuleCompiler(name: name, analysisModule: analyzed, moduleEnvironment: moduleEnvironment).compile(mode: .executable)
		return (module, analyzed)
	}

	func run(_ strings: String...) -> TalkTalkBytecode.Value {
		let module = try! compile(strings)
		return VirtualMachine.run(module: module).get()
	}

	@Test("Adds") func adds() {
		#expect(run("1 + 2") == .int(3))
	}

	@Test("Subtracts") func subtracts() {
		#expect(run("2 - 1") == .int(1))
	}

	@Test("Comparison") func comparison() {
		#expect(run("1 == 2") == .bool(false))
		#expect(run("2 == 2") == .bool(true))

		#expect(run("1 != 2") == .bool(true))
		#expect(run("2 != 2") == .bool(false))

		#expect(run("1 < 2") == .bool(true))
		#expect(run("2 < 1") == .bool(false))

		#expect(run("1 > 2") == .bool(false))
		#expect(run("2 > 1") == .bool(true))

		#expect(run("1 <= 2") == .bool(true))
		#expect(run("2 <= 1") == .bool(false))
		#expect(run("2 <= 2") == .bool(true))

		#expect(run("1 >= 2") == .bool(false))
		#expect(run("2 >= 1") == .bool(true))
		#expect(run("2 >= 2") == .bool(true))
	}

	@Test("Negate") func negate() {
		#expect(run("-123") == .int(-123))
		#expect(run("--123") == .int(123))
	}

	@Test("Not") func not() {
		#expect(run("!true") == .bool(false))
		#expect(run("!false") == .bool(true))
	}

	@Test("Strings") func strings() {
		#expect(run(#""hello world""#) == .data(0))
	}

	@Test("If expr") func ifExpr() {
		#expect(run("""
		if false {
			123
		} else {
			456
		}
		""") == .int(456))
	}

	@Test("Var expr") func varExpr() {
		#expect(run("""
		a = 10
		b = 20
		a = a + b
		a
		""") == .int(30))
	}

	@Test("Basic func/call expr") func funcExpr() {
		#expect(run("""
		i = func() {
			123
		}()

		i + 1
		""") == .int(124))
	}

	@Test("Func arguments") func funcArgs() {
		#expect(run("""
		func(i) {
			i + 20
		}(10)
		""") == .int(30))
	}

	@Test("Get var from enlosing scope") func enclosing() {
		#expect(run("""
		a10 = 10
		b20 = 20
		func() {
			c30 = 30
			a10 + b20 + c30
		}()
		""") == .int(60))
	}

	@Test("Modify var from enclosing scope") func modifyEnclosing() {
		#expect(run("""
		a = 10
		func() {
			a = 20
		}()
		a
		""") == .int(20))
	}

	@Test("Works with counter") func counter() {
		#expect(run("""
		func makeCounter() {
			count = 0
			func increment() {
				count = count + 1
				count
			}
			increment
		}

		mycounter = makeCounter()
		mycounter()
		mycounter()
		""") == .int(2))
	}

	@Test("Doesn't leak out of closures") func closureLeak() throws {
		#expect(throws: CompilerError.self) {
			try compile("""
			func() {
			 a = 123
			}

			a
			""")
		}
	}

	@Test("Can run functions across files") func crossFile() throws {
		let out = captureOutput {
			run(
				"print(fizz())",
				"func foo() { bar() }",
				"func bar() { 123 }",
				"func fizz() { foo() }"
			)
		}

		#expect(out.output == ".int(123)\n")
	}

	@Test("Can use values across files") func crossFileValues() throws {
		let out = captureOutput {
			run(
				"print(fizz)",
				"print(fizz)",
				"fizz = 123"
			)
		}

		#expect(out.output == ".int(123)\n.int(123)\n")
	}

	@Test("Can run functions across modules") func crossModule() throws {
		let (moduleA, analysisA) = compile(name: "A", [.tmp("func foo() { 123 }")], analysisEnvironment: [:], moduleEnvironment: [:])
		let (moduleB, _) = compile(
			name: "B",
			[
				.tmp(
					"""
					import A

					func bar() {
						print(foo())
					}

					bar()
					"""
				)
			],
			analysisEnvironment: ["A": analysisA],
			moduleEnvironment: ["A": moduleA]
		)

		let out = captureOutput {
			VirtualMachine.run(module: moduleB)
		}

		#expect(out.output == ".int(123)\n")
	}

	// MARK: helpers

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
