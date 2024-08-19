//
//  REPLRunner.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/14/24.
//

import TalkTalkAnalysis
import TalkTalkBytecode
import TalkTalkCompiler
import TalkTalkCore
import TalkTalkDriver
import TalkTalkSyntax

public struct REPLRunner: Copyable {
	let driver: Driver
	var module: Module
	var analysis: AnalysisModule
	var vm: VirtualMachine
	let environment: Environment
	var chunk: Chunk
	var compiler: ChunkCompiler
	var compilingModule: CompilingModule

	public static func run() async throws {
		var runner = await REPLRunner()
		try await runner.run()
	}

	public init() async {
		let stdlib = try! await StandardLibrary.compile()
		self.driver = Driver(
			directories: [Library.replURL],
			analyses: ["Standard": stdlib.analysis],
			modules: ["Standard": stdlib.module]
		)

		let result = try! await driver.compile(mode: .module)["REPL"]!
		self.module = result.module
		self.analysis = result.analysis
		self.environment = Environment()
		environment.exprStmtExitBehavior = .none
		self.compilingModule = CompilingModule(
			name: "REPL",
			analysisModule: analysis,
			moduleEnvironment: [:]
		)
		self.chunk = Chunk(name: "main")
		module.main = chunk
		self.compiler = ChunkCompiler(module: compilingModule)
		self.vm = VirtualMachine(module: module)
	}

	public mutating func evaluate(_ line: String, index _: Int) throws -> VirtualMachine.ExecutionResult {
		if line.isEmpty { return .error("No input") }

		let parsed = try Parser.parse(SourceFile(path: "<repl>", text: line))
		let analyzed = try SourceFileAnalyzer.analyze(parsed, in: environment)
		for syntax in analyzed {
			if let syntax = syntax as? AnalyzedExprStmt {
				// Unwrap expr stmt because we don't just want to pop the value
				// off the stack.
				try syntax.exprAnalyzed.accept(compiler, chunk)
			} else {
				try syntax.accept(compiler, chunk)
			}
		}

		chunk.emit(opcode: .suspend, line: .zero)

		return vm.run()
	}

	public mutating func run() async throws {
		print("hey welcome to the talktalk repl. it’s gonna be great.")

		var i = 0

		while true {
			print("talk:\("\(String(format: "%03d", i))")> ", terminator: "")
			guard let line = readLine() else {
				return
			}

			do {
				let result = try evaluate(line, index: i)
				print(result)
			} catch {
				print("Caught error: \(error)")
			}

			i += 1
		}
	}
}
