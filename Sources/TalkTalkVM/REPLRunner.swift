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
import TalkTalkCore
import TypeChecker

public enum REPLError: Error {
	case initError(String)
}

public class REPLRunner: Copyable {
	let driver: Driver
	var module: Module
	var analysis: AnalysisModule
	var vm: VirtualMachine
	let environment: Environment
	var chunk: Chunk
	var compiler: ChunkCompiler
	var compilingModule: CompilingModule
	var typer: Typer

	public static func run() async throws {
		let runner = try await REPLRunner()
		try await runner.run()
	}

	static func compileStandardLibrary() throws -> (Module, AnalysisModule) {
		let analysis = try ModuleAnalyzer(
			name: "Standard",
			files: Library.standard.files.map { try Parser.parseFile($0) },
			moduleEnvironment: [:],
			importedModules: []
		).analyze()

		let compiler = ModuleCompiler(
			name: "Standard",
			analysisModule: analysis
		)

		let stdlib = try compiler.compile(mode: .module)

		return (stdlib, analysis)
	}

	public init() async throws {
		let (stdlibModule, stdlibAnalysis) = try Self.compileStandardLibrary()

		self.driver = Driver(
			directories: [],
			analyses: ["Standard": stdlibAnalysis],
			modules: ["Standard": stdlibModule]
		)

		let analysisModule = try ModuleAnalyzer(
			name: "REPL",
			files: [],
			moduleEnvironment: ["Standard": stdlibAnalysis],
			importedModules: [stdlibAnalysis]
		).analyze()

		let moduleCompiler = ModuleCompiler(
			name: "REPL",
			analysisModule: analysisModule
		)

		self.module = try moduleCompiler.compile(mode: .executable)
		self.analysis = analysisModule
		self.typer = try Typer(module: "REPL", imports: [])
		self.environment = Environment(inferenceContext: typer.context, symbolGenerator: .init(moduleName: "REPL", parent: nil))
		environment.exprStmtExitBehavior = .none
		self.compilingModule = CompilingModule(
			name: "REPL",
			analysisModule: analysis,
			moduleEnvironment: [:]
		)
		self.chunk = Chunk(name: "main", symbol: .function("REPL", "main", []), path: "<repl>")
		module.main = StaticChunk(chunk: chunk)
		self.compiler = ChunkCompiler(module: compilingModule)
		self.vm = try VirtualMachine(module: module)
	}

	public func evaluate(_ line: String, index _: Int) throws -> VirtualMachine.ExecutionResult {
		if line.isEmpty { return .error("No input") }
		let parsed = try Parser.parse(SourceFile(path: "<repl>", text: line))

		_ = try typer.solve(parsed)

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
		vm.set(chunk: StaticChunk(chunk: chunk))

		return try vm.run()
	}

	public func run() async throws {
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
