//
//  ModuleCompiler.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/7/24.
//

import TalkTalkAnalysis
import TalkTalkBytecode
import TalkTalkSyntax
import TalkTalkCore
import TypeChecker

public typealias BuiltinFunction = TypeChecker.BuiltinFunction

public struct ModuleCompiler {
	let name: String
	let analysisModule: AnalysisModule
	var moduleEnvironment: [String: Module]

	public init(
		name: String,
		analysisModule: AnalysisModule,
		moduleEnvironment: [String: Module] = [:]
	) {
		self.name = name
		self.analysisModule = analysisModule
		self.moduleEnvironment = moduleEnvironment
	}

	func compileStandardLibrary() throws -> (Module, AnalysisModule)? {
		guard moduleEnvironment["Standard"] == nil else {
			// We've already got it, we're good
			return nil
		}

		let analysis = try ModuleAnalyzer(
			name: "Standard",
			files: Library.standard.paths.map {
				let parsed = try Parser.parse(
					SourceFile(
						path: $0,
						text: String(
							contentsOf: Library.standard.location.appending(path: $0),
							encoding: .utf8
						)
					)
				)

				return ParsedSourceFile(path: $0, syntax: parsed)
			},
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

	public func compile(mode: CompilationMode, allowErrors: Bool = false) throws -> Module {
		let errors = try analysisModule.collectErrors()
		if !errors.isEmpty, !allowErrors {
			throw CompilerError.analysisErrors("Cannot compile \(name), found \(errors.count) analysis errors: \(errors.all.map(\.description))")
		}

		var moduleEnvironment = self.moduleEnvironment

		if name != "Standard", let (stdlibModule, _) = try compileStandardLibrary() {
			moduleEnvironment["Standard"] = stdlibModule
		}

		let module = CompilingModule(
			name: name,
			analysisModule: analysisModule,
			moduleEnvironment: moduleEnvironment
		)

		for file in analysisModule.analyzedFiles {
			_ = try module.compile(file: file)
		}

		return try module.finalize(mode: mode)
	}
}
