//
//  AnalysisModule.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/7/24.
//

import Foundation
import TalkTalkSyntax

public struct SerializedAnalysisModule: Codable {
	public let name: String
	public let files: [String]
	public let values: [String: SerializedModuleGlobal]
	public let functions: [String: SerializedModuleGlobal]

	static func serialize(_ global: ModuleGlobal) -> SerializedModuleGlobal {
		let source: SerializedModuleGlobal.SerializedModuleSource = if case let .external(module) = global.source {
			.external(module.name)
		} else {
			.module
		}

		return SerializedModuleGlobal(
			name: global.name,
			type: global.typeID.current,
			globalType: global is ModuleValue ? .value : .function,
			source: source
		)
	}

	public init(analysisModule: AnalysisModule) {
		self.name = analysisModule.name
		self.files = analysisModule.files.map(\.path)
		self.values = analysisModule.values.reduce(into: [:]) { res, value in
			let (name, global) = value
			res[name] = SerializedAnalysisModule.serialize(global)
		}

		self.functions = analysisModule.moduleFunctions.reduce(into: [:]) { res, value in
			let (name, global) = value
			res[name] = SerializedAnalysisModule.serialize(global)
		}
	}
}

public struct AnalysisModule {
	public let name: String

	public var files: Set<ParsedSourceFile>

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

	// A list of modules this module imports
	public var imports: [String: ModuleGlobal] = [:]

	public func moduleValue(named name: String) -> ModuleValue? {
		values[name]
	}

	public func moduleFunction(named name: String) -> ModuleFunction? {
		moduleFunctions[name]
	}

	public func moduleGlobal(named name: String) -> (any ModuleGlobal)? {
		moduleFunction(named: name) ?? moduleValue(named: name)
	}

	public func moduleStruct(named name: String) -> ModuleStruct? {
		structs[name]
	}

	public func collectLocalFunctions() -> [ModuleFunction] {
		func collect(in syntax: any AnalyzedSyntax) -> [ModuleFunction] {
			var result: [ModuleFunction] = []
			if let syntax = syntax as? AnalyzedFuncExpr {
				if let name = syntax.name?.lexeme {
					result.append(ModuleFunction(name: name, syntax: syntax, typeID: syntax.typeID, source: .module))
				}
			}

			for child in syntax.analyzedChildren {
				result.append(contentsOf: collect(in: child))
			}

			return result
		}

		return analyzedFiles.flatMap(\.syntax).flatMap { collect(in: $0) }
	}
}

public extension AnalysisModule {
	static func empty(_ name: String) -> AnalysisModule {
		AnalysisModule(name: name, files: [])
	}
}
