//
//  ModuleAnalyzer.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/7/24.
//

import TalkTalkBytecode
import TalkTalkCore
import TalkTalkCore
import TypeChecker

public struct ModuleAnalyzer: Analyzer {
	enum Error: Swift.Error {
		case moduleNotFound(String)
	}

	// swiftlint:disable force_try
	public nonisolated(unsafe) static let stdlib: AnalysisModule = try! ModuleAnalyzer(
		// swiftlint:enable force_try
		name: "Standard",
		files: Library.standard.files.map { try Parser.parseFile($0) },
		moduleEnvironment: [:],
		importedModules: []
	).analyze()

	public let name: String
	public var files: [ParsedSourceFile]
	public let environment: Environment
	let visitor: SourceFileAnalyzer
	public var moduleEnvironment: [String: AnalysisModule]
	public var importedModules: [AnalysisModule]
	let typer: Typer

	public init(
		name: String,
		files: [ParsedSourceFile],
		moduleEnvironment: [String: AnalysisModule],
		importedModules _: [AnalysisModule]
	) throws {
		self.name = name
		self.files = files
		self.typer = try Typer(module: name, imports: moduleEnvironment.values.map(\.inferenceContext), verbose: true, debugStdlib: true)
		self.environment = .topLevel(name, inferenceContext: typer.context)
		self.visitor = SourceFileAnalyzer()
		self.moduleEnvironment = moduleEnvironment
		self.importedModules = moduleEnvironment.values.map { $0 }

		if moduleEnvironment["Standard"] == nil, name != "Standard" {
			let stdlib = try importStandardLibrary()
			self.moduleEnvironment["Standard"] = stdlib
			importedModules.append(stdlib)
		}
	}

	public func importStandardLibrary() throws -> AnalysisModule {
		ModuleAnalyzer.stdlib
	}

	public func analyze() throws -> AnalysisModule {
		for file in files {
			_ = try typer.solve(file.syntax)
		}

		var analysisModule = AnalysisModule(name: name, inferenceContext: typer.context, files: files)

		for module in importedModules {
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

		try importSymbols(into: &analysisModule)

		// Once we've got globals established, we can go through and actually analyze
		// all the files for the module. TODO: Also establish imports.
		//
		// We also need to make sure the files are in the correct order.
		analysisModule.analyzedFiles = try files.map {
			if name != "Standard" {
				let sym = environment.symbolGenerator.function($0.path, parameters: [], source: .internal)
				analysisModule.symbols[sym] = environment.symbolGenerator[sym]
			}

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
		try importSymbols(into: &analysisModule)

		for (symbol, info) in environment.symbolGenerator.symbols {
			analysisModule.symbols[symbol] = info
		}

		return analysisModule
	}

	private func importSymbols(into analysisModule: inout AnalysisModule) throws {
		for (symbol, binding) in environment.importedSymbols {
			guard let module = binding.externalModule else {
				throw AnalyzerError.symbolNotFound("could not get module for symbol `\(name)`")
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
					id: structType.id,
					name: name,
					symbol: symbol,
					location: binding.location,
					typeID: binding.type,
					source: .external(module),
					properties: structType.properties,
					methods: structType.methods,
					typeParameters: structType.typeParameters
				)
			} else if case let .enum(name) = symbol.kind,
			          let enumType = binding.externalModule?.enums[name]
			{
				analysisModule.enums[name] = ModuleEnum(
					name: name,
					symbol: symbol,
					location: binding.location,
					typeID: binding.type,
					source: .external(module),
					methods: enumType.methods
				)
			} else {
				throw AnalyzerError.symbolNotFound("unhandled exported symbol: \(symbol)")
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
			} else if let enumT = global as? ModuleEnum {
				analysisModule.enums[enumT.name] = enumT
			} else {
				throw AnalyzerError.symbolNotFound("unhandled exported symbol: \(name)")
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

	// Go through top level values before actually doing analysis so we can try to get global names.
	private func analyze(syntax: any Syntax, in _: AnalysisModule) throws -> [String: ModuleGlobal] {
		var result: [String: ModuleGlobal] = [:]

		var syntax = syntax

		// Unwrap expr statements
		if let exprStmt = syntax as? ExprStmt {
			syntax = exprStmt.expr
		}

		switch syntax {
		case let syntax as EnumDecl:
			guard let analyzed = try syntax.accept(visitor, environment) as? AnalyzedEnumDecl else {
				break
			}

			let symbol = analyzed.symbol
			result[analyzed.nameToken.lexeme] = ModuleEnum(
				name: analyzed.nameToken.lexeme,
				symbol: symbol,
				location: syntax.location,
				typeID: analyzed.inferenceType,
				source: .module,
				methods: [:]
			)

			environment.define(
				local: analyzed.nameToken.lexeme,
				as: analyzed,
				isMutable: false
			)
		case let syntax as VarDecl:
			guard let analyzed = try syntax.accept(visitor, environment) as? AnalyzedVarDecl else {
				break
			}

			guard let symbol = analyzed.symbol else {
				throw AnalyzerError.symbolNotFound("expected symbol for: \(syntax)")
			}

			result[syntax.name] = ModuleValue(
				name: syntax.name,
				symbol: symbol,
				location: syntax.location,
				typeID: analyzed.inferenceType,
				source: .module,
				isMutable: true
			)
		case let syntax as LetDecl:
			guard let analyzed = try syntax.accept(visitor, environment) as? AnalyzedLetDecl else {
				break
			}

			guard let symbol = analyzed.symbol else {
				throw AnalyzerError.symbolNotFound("expected symbol for: \(syntax)")
			}

			result[syntax.name] = ModuleValue(
				name: syntax.name,
				symbol: symbol,
				location: syntax.location,
				typeID: analyzed.inferenceType,
				source: .module,
				isMutable: false
			)
		case let syntax as FuncExpr:
			// Named functions get added as globals at the top level
			if let name = syntax.name {
				guard let analyzed = try syntax.accept(visitor, environment) as? AnalyzedFuncExpr else {
					break
				}

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
			guard let analyzed = try syntax.accept(visitor, environment) as? AnalyzedDefExpr else {
				break
			}

			if let syntax = analyzed.receiverAnalyzed as? AnalyzedVarExpr {
				guard let symbol = syntax.symbol else {
					throw AnalyzerError.symbolNotFound("expected symbol for \(syntax)")
				}

				result[syntax.name] = ModuleValue(
					name: syntax.name,
					symbol: symbol,
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
			guard let analyzedStructDecl = try syntax.accept(visitor, environment) as? AnalyzedStructDecl else {
				break
			}

			let name = analyzedStructDecl.name
			result[name] = ModuleStruct(
				id: analyzedStructDecl.id,
				name: name,
				symbol: analyzedStructDecl.symbol,
				location: syntax.location,
				typeID: analyzedStructDecl.inferenceType,
				source: .module,
				properties: analyzedStructDecl.structType.properties,
				methods: analyzedStructDecl.structType.methods,
				typeParameters: analyzedStructDecl.structType.typeParameters
			)
		default:
			()
		}

		return result
	}
}
