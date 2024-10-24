//
//  AnalysisModule.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/7/24.
//

import OrderedCollections
import TalkTalkBytecode
import TalkTalkCore
import TypeChecker

public struct AnalysisModule {
	public let name: String

	public let inferenceContext: TypeChecker.Context

	public var files: any Collection<ParsedSourceFile>

	// Keep track of all the different symbols in this module
	public var symbols: OrderedDictionary<Symbol, SymbolInfo> = [:]

	// The list of analyzed files for this module (this is built up by the module analyzer)
	public var analyzedFiles: [AnalyzedSourceFile] = []

	// The list of global values in this module
	public var values: [String: ModuleValue] = [:]

	// The list of top level functions in this module
	public var moduleFunctions: [String: ModuleFunction] = [:]

	// The list of non-top level functions in this module
	public var localFunctions: [String: ModuleFunction] = [:]

	// The list of top level structs in this module
	public var structs: [String: ModuleStruct] = [:]

	// This list of top level enums in this module
	public var enums: [String: ModuleEnum] = [:]

	public var protocols: [String: ModuleProtocol] = [:]

	// A list of modules this module imports
	public var imports: OrderedDictionary<String, ModuleGlobal> = [:]

	public func moduleValue(named name: String) -> ModuleValue? {
		values[name]
	}

	public func moduleFunction(named name: String) -> ModuleFunction? {
		moduleFunctions[name]
	}

	public func moduleGlobal(named name: String) -> (any ModuleGlobal)? {
		moduleFunction(named: name) ?? moduleValue(named: name)
	}

	public func moduleEnum(named name: String) -> ModuleEnum? {
		enums[name]
	}

	public func moduleStruct(named name: String) -> ModuleStruct? {
		structs[name]
	}

	public func collectLocalFunctions() -> [ModuleFunction] {
		func collect(in syntax: any AnalyzedSyntax) -> [ModuleFunction] {
			var result: [ModuleFunction] = []
			if let syntax = syntax as? AnalyzedFuncExpr {
				if let name = syntax.name?.lexeme {
					result.append(
						ModuleFunction(
							name: name,
							symbol: syntax.symbol,
							location: syntax.location,
							typeID: syntax.inferenceType,
							source: .module
						)
					)
				}
			}

			for child in syntax.analyzedChildren {
				result.append(contentsOf: collect(in: child))
			}

			return result
		}

		return analyzedFiles.flatMap(\.syntax).flatMap { collect(in: $0) }
	}

	public func lookup(function name: String) -> SymbolInfo? {
		for (symbol, info) in symbols {
			if case let .function(fnName, _) = symbol.kind, name == fnName {
				return info
			}
		}

		return nil
	}

	public func lookup(symbol kind: Symbol.Kind) -> SymbolInfo? {
		symbols[Symbol(module: name, kind: kind)]
	}
}

public extension AnalysisModule {
	static func empty(_ name: String) -> AnalysisModule {
		// swiftlint:disable force_try
		AnalysisModule(name: name, inferenceContext: try! Typer(module: "", imports: []).solve([]), files: [])
		// swiftlint:enable force_try
	}
}
