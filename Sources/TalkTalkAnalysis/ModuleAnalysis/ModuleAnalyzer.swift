//
//  ModuleAnalyzer.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/7/24.
//

import TalkTalkSyntax

public struct ModuleAnalyzer {
	enum Error: Swift.Error {
		case moduleNotFound(String)
	}

	let name: String
	let files: [ParsedSourceFile]
	let environment: Environment
	let visitor: SourceFileAnalyzer
	let moduleEnvironment: [String: AnalysisModule]

	public init(name: String, files: [ParsedSourceFile], moduleEnvironment: [String: AnalysisModule]) {
		self.name = name
		self.files = files
		self.environment = Environment(isModuleScope: true)
		self.visitor = SourceFileAnalyzer()
		self.moduleEnvironment = moduleEnvironment
	}

	public func analyze() throws -> AnalysisModule {
		var analysisModule = AnalysisModule(name: name, files: files)

		// Find all the top level stuff this module has to offer
		for file in files {
			try processFile(file: file, in: &analysisModule)
		}

		// Mark any found bindings as global
		for binding in environment.bindings {
			binding.isGlobal = true
		}

		// Do a second pass so things that were defined in other files can
		// get picked up. TODO: There's gotta be a better way.
		for file in files {
			try processFile(file: file, in: &analysisModule)
		}

		for (name, binding) in environment.importedSymbols {
			guard let module = binding.externalModule else {
				fatalError("could not get module for symbol `\(name)`")
			}

			if case let .function(name) = name {
				analysisModule.functions[name] = ModuleFunction(
					name: name,
					syntax: binding.expr,
					type: binding.type,
					source: .external(module)
				)
			} else if case let .value(name) = name {
				analysisModule.values[name] = ModuleValue(
					name: name,
					syntax: binding.expr,
					type: binding.type,
					source: .external(module)
				)
			}
		}

		// Once we've got globals established, we can go through and actually analyze
		// all the files for the module. TODO: Also establish imports.
		//
		// We also need to make sure the files are in the correct order.
		analysisModule.analyzedFiles = try files.map {
			try AnalyzedSourceFile(path: $0.path, syntax: $0.syntax.map {
				try $0.accept(visitor, environment)
			})
		}

		return analysisModule
	}

	private func processFile(file: ParsedSourceFile, in analysisModule: inout AnalysisModule) throws {
		for (name, global) in try analyze(file: file, in: analysisModule) {
			if let global = global as? ModuleValue {
				analysisModule.values[name] = global
			} else if let global = global as? ModuleFunction {
				analysisModule.functions[name] = global
			} else if let structT = global as? ModuleStruct {
				analysisModule.structs[structT.name] = structT
			} else {
				fatalError()
			}
		}
	}

	// Get the top level stuff from this file since that's where globals live.
	private func analyze(file: ParsedSourceFile, in module: AnalysisModule) throws -> [String: ModuleGlobal] {
		var result: [String: ModuleGlobal] = [:]

		// Do a first pass over the file to find everything
		for syntax in file.syntax {
			let analyzed = try analyze(syntax: syntax, in: module)

			// TODO: Handle case where names clash
			result.merge(analyzed, uniquingKeysWith: { $1 })
		}

		return result
	}

	private func analyze(syntax: any Syntax, in module: AnalysisModule) throws -> [String: ModuleGlobal] {
		var result: [String: ModuleGlobal] = [:]

		switch syntax {
		case let syntax as FuncExpr:
			// Named functions get added as globals at the top level
			if let name = syntax.name {
				let analyzed = try visitor.visit(syntax, environment)
				result[name.lexeme] = ModuleFunction(
					name: name.lexeme,
					syntax: syntax,
					type: analyzed.type,
					source: .module
				)
			}
		case let syntax as DefExpr:
			// Def exprs also get added as globals at the top level
			let analyzed = try visitor.visit(syntax, environment)

			result[syntax.name.lexeme] = ModuleValue(
				name: syntax.name.lexeme,
				syntax: syntax,
				type: analyzed.type,
				source: .module
			)
		case let syntax as ImportStmt:
			guard let module = moduleEnvironment[syntax.module.name] else {
				throw Error.moduleNotFound("\(syntax.module.name) module not found")
			}

			environment.importModule(module)
		case let syntax as StructExpr:
			let structExpr = try visitor.visit(syntax, environment).cast(AnalyzedStructExpr.self)
			let name = structExpr.name ?? "<struct\(module.structs.count)>"
			result[name] = ModuleStruct(
				name: name,
				syntax: syntax,
				type: structExpr.type,
				source: .module,
				properties: structExpr.lexicalScope.scope.properties,
				methods: structExpr.lexicalScope.scope.methods
			)
		default:
			()
		}

		return result
	}
}
