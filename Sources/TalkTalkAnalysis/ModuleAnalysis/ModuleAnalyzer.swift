//
//  ModuleAnalyzer.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/7/24.
//

import TalkTalkCore
import TalkTalkBytecode
import TalkTalkSyntax
import TypeChecker

public struct ModuleAnalyzer {
	enum Error: Swift.Error {
		case moduleNotFound(String)
	}

	public let name: String
	public var files: [ParsedSourceFile]
	public let environment: Environment
	let visitor: SourceFileAnalyzer
	public var moduleEnvironment: [String: AnalysisModule]
	public var importedModules: [AnalysisModule]
	let inferencer: Inferencer

	public init(
		name: String,
		files: [ParsedSourceFile],
		moduleEnvironment: [String: AnalysisModule],
		importedModules: [AnalysisModule]
	) {
		self.name = name
		self.files = files
		self.inferencer = Inferencer(imports: moduleEnvironment.values.map(\.inferenceContext))
		self.environment = .topLevel(name, inferenceContext: inferencer.context)
		self.visitor = SourceFileAnalyzer()
		self.moduleEnvironment = moduleEnvironment
		self.importedModules = moduleEnvironment.values.map { $0 }

		if moduleEnvironment["Standard"] == nil, name != "Standard" {
			let stdlib = try! importStandardLibrary()
			self.moduleEnvironment["Standard"] = stdlib
			self.importedModules.append(stdlib)
		}
	}

	public func importStandardLibrary() throws -> AnalysisModule {
		try ModuleAnalyzer(
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
	}

	public func analyze() throws -> AnalysisModule {
		for file in files {
			_ = inferencer.infer(file.syntax)
		}

		_ = inferencer.inferDeferred()

		var analysisModule = AnalysisModule(name: name, inferenceContext: inferencer.context, files: files)

		for module in importedModules.sorted(by: { ($0.name == "Standard" ? 0 : 1) < ($1.name == "Standard" ? 0 : 1) }) {
			if module.name == "Standard", name != "Standard" {
				// Always make standard types available
				for (name, structType) in module.structs {
					analysisModule.structs[name] = ModuleStruct(
						name: name,
						symbol: structType.symbol,
						location: structType.location,
						typeID: structType.typeID,
						source: .external(module),
						properties: structType.properties,
						methods: structType.methods,
						typeParameters: structType.typeParameters
					)
				}
			}

			environment.importModule(module)
		}

		// Find all the top level stuff this module has to offer. We ignore errors at this
		// stage because we're just getting started
		try environment.ignoringErrors {
			for file in files {
				try processFile(file: file, in: &analysisModule)
			}
		}

		// Mark any found bindings as global
		for binding in environment.bindings {
			binding.isGlobal = true
		}

		// Do a second pass so things that were defined in other files can
		// get picked up. TODO: There's gotta be a better way.
		try environment.ignoringErrors {
			for file in files {
				try processFile(file: file, in: &analysisModule)
			}
		}

		importSymbols(into: &analysisModule)

		// Once we've got globals established, we can go through and actually analyze
		// all the files for the module. TODO: Also establish imports.
		//
		// We also need to make sure the files are in the correct order.
		analysisModule.analyzedFiles = try files.map {
			let sym = environment.symbolGenerator.function($0.path, parameters: [], source: .internal)
			analysisModule.symbols[sym] = environment.symbolGenerator[sym]

			return try AnalyzedSourceFile(
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

		for (symbol, info) in environment.symbolGenerator.symbols {
			analysisModule.symbols[symbol] = info
		}

		return analysisModule
	}

	private func importSymbols(into analysisModule: inout AnalysisModule) {
		for (symbol, binding) in environment.importedSymbols {
			guard let module = binding.externalModule else {
				fatalError("could not get module for symbol `\(name)`")
			}

			if case let .function(name, _) = symbol.kind {
				analysisModule.moduleFunctions[name] = ModuleFunction(
					name: name,
					symbol: symbol,
					location: binding.location,
					typeID: binding.type,
					source: .external(module)
				)
			} else if case let .value(name) = symbol.kind {
				analysisModule.values[name] = ModuleValue(
					name: name,
					symbol: symbol,
					location: binding.location,
					typeID: binding.type,
					source: .external(module),
					isMutable: false
				)
			} else if case let .struct(name) = symbol.kind,
								let structType = binding.externalModule?.structs[name]
			{
				analysisModule.structs[name] = ModuleStruct(
					name: name,
					symbol: symbol,
					location: binding.location,
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
				analysisModule.moduleFunctions[name] = global
			} else if let structT = global as? ModuleStruct {
				analysisModule.structs[structT.name] = structT
			} else {
				fatalError()
			}
		}
	}

	// Get the top level stuff from this file since that's where globals live.
	private func analyze(file: ParsedSourceFile, in module: AnalysisModule) throws -> [String:
		ModuleGlobal]
	{
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
			let analyzed = try visitor.visit(syntax.cast(VarDeclSyntax.self), environment) as! AnalyzedVarDecl

			result[syntax.name] = ModuleValue(
				name: syntax.name,
				symbol: analyzed.symbol!,
				location: syntax.location,
				typeID: analyzed.inferenceType,
				source: .module,
				isMutable: true
			)
		case let syntax as LetDecl:
			let analyzed = try visitor.visit(syntax.cast(LetDeclSyntax.self), environment) as! AnalyzedLetDecl

			result[syntax.name] = ModuleValue(
				name: syntax.name,
				symbol: analyzed.symbol!,
				location: syntax.location,
				typeID: analyzed.inferenceType,
				source: .module,
				isMutable: false
			)
		case let syntax as FuncExpr:
			// Named functions get added as globals at the top level
			if let name = syntax.name {
				let analyzed = try visitor.visit(syntax.cast(FuncExprSyntax.self), environment) as! AnalyzedFuncExpr
				result[name.lexeme] = ModuleFunction(
					name: name.lexeme,
					symbol: analyzed.symbol,
					location: syntax.location,
					typeID: analyzed.inferenceType,
					source: .module
				)
			}
		case let syntax as DefExpr:
			// Def exprs also get added as globals at the top level
			let analyzed = try visitor.visit(syntax.cast(DefExprSyntax.self), environment) as! AnalyzedDefExpr

			if let syntax = analyzed.receiverAnalyzed as? AnalyzedVarExpr {
				result[syntax.name] = ModuleValue(
					name: syntax.name,
					symbol: syntax.symbol!,
					location: syntax.location,
					typeID: analyzed.inferenceType,
					source: .module,
					isMutable: false
				)
			}
		case let syntax as ImportStmt:
			guard let module = moduleEnvironment[syntax.module.name] else {
				throw Error.moduleNotFound("\(syntax.module.name) module not found")
			}

			environment.inferenceContext.import(module.inferenceContext)
		case let syntax as StructDecl:
			let analyzedStructDecl = try visitor.visit(syntax.cast(StructDeclSyntax.self), environment).cast(AnalyzedStructDecl.self)
			let name = analyzedStructDecl.name
			result[name] = ModuleStruct(
				name: name,
				symbol: analyzedStructDecl.symbol,
				location: syntax.location,
				typeID: analyzedStructDecl.inferenceType,
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
