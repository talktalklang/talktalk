//
//  ModuleAnalyzer.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/7/24.
//

import TalkTalkCore
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

	public init(
		name: String,
		files: [ParsedSourceFile],
		moduleEnvironment: [String: AnalysisModule],
		importedModules: [AnalysisModule]
	) {
		self.name = name
		self.files = files
		self.environment = Environment(isModuleScope: true)
		self.visitor = SourceFileAnalyzer()
		self.moduleEnvironment = moduleEnvironment

		for module in importedModules {
			environment.importModule(module)
		}
	}

	public var errors: [AnalysisError] {
		environment.errors
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

		importSymbols(into: &analysisModule)

		// Once we've got globals established, we can go through and actually analyze
		// all the files for the module. TODO: Also establish imports.
		//
		// We also need to make sure the files are in the correct order.
		analysisModule.analyzedFiles = try files.map {
			try AnalyzedSourceFile(
				path: $0.path,
				syntax: SourceFileAnalyzer.analyze(
					$0.syntax,
					in: environment
				)
			)
		}

		// Now that we've walked the tree, we should make sure we're not missing any
		// other symbols.
		importSymbols(into: &analysisModule)

		return analysisModule
	}

	private func importSymbols(into analysisModule: inout AnalysisModule) {
		for (name, binding) in environment.importedSymbols {
			guard let module = binding.externalModule else {
				fatalError("could not get module for symbol `\(name)`")
			}

			if case let .function(name) = name {
				analysisModule.functions[name] = ModuleFunction(
					name: name,
					syntax: binding.expr,
					typeID: binding.type,
					source: .external(module)
				)
			} else if case let .value(name) = name {
				analysisModule.values[name] = ModuleValue(
					name: name,
					syntax: binding.expr,
					typeID: binding.type,
					source: .external(module)
				)
			} else if case let .struct(name) = name,
								let structType = binding.externalModule?.structs[name]
			{
				analysisModule.structs[name] = ModuleStruct(
					name: name,
					syntax: binding.expr,
					typeID: binding.type,
					source: .external(module),
					properties: structType.properties,
					methods: structType.methods,
					typeParameters: structType.typeParameters
				)
			} else {
				fatalError("unhandled exported symbol: \(name)")
			}
		}
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

	private func analyze(syntax: any Syntax, in _: AnalysisModule) throws -> [String: ModuleGlobal] {
		var result: [String: ModuleGlobal] = [:]

		var syntax = syntax

		// Unwrap expr statements
		if let exprStmt = syntax as? ExprStmt {
			syntax = exprStmt.expr
		}

		switch syntax {
		case let syntax as VarDecl:
			let analyzed = try visitor.visit(syntax, environment)

			result[syntax.name] = ModuleValue(
				name: syntax.name,
				syntax: syntax,
				typeID: analyzed.typeID,
				source: .module
			)
		case let syntax as LetDecl:
			let analyzed = try visitor.visit(syntax, environment)

			result[syntax.name] = ModuleValue(
				name: syntax.name,
				syntax: syntax,
				typeID: analyzed.typeID,
				source: .module
			)
		case let syntax as FuncExpr:
			// Named functions get added as globals at the top level
			if let name = syntax.name {
				let analyzed = try visitor.visit(syntax, environment)
				result[name.lexeme] = ModuleFunction(
					name: name.lexeme,
					syntax: syntax,
					typeID: analyzed.typeID,
					source: .module
				)
			}
		case let syntax as DefExpr:
			// Def exprs also get added as globals at the top level
			let analyzed = try visitor.visit(syntax, environment)

			if let syntax = syntax.receiver as? VarExprSyntax {
				result[syntax.name] = ModuleValue(
					name: syntax.name,
					syntax: syntax,
					typeID: analyzed.typeID,
					source: .module
				)
			}
		case let syntax as ImportStmt:
			guard let module = moduleEnvironment[syntax.module.name] else {
				throw Error.moduleNotFound("\(syntax.module.name) module not found")
			}

			environment.importModule(module)
		case let syntax as StructDecl:
			let analyzedStructDecl = try visitor.visit(syntax, environment).cast(AnalyzedStructDecl.self)
			let name = analyzedStructDecl.name
			result[name] = ModuleStruct(
				name: name,
				syntax: syntax,
				typeID: analyzedStructDecl.typeID,
				source: .module,
				properties: analyzedStructDecl.lexicalScope.scope.properties,
				methods: analyzedStructDecl.lexicalScope.scope.methods,
				typeParameters: analyzedStructDecl.lexicalScope.scope.typeParameters
			)
		default:
			()
		}

		return result
	}
}
