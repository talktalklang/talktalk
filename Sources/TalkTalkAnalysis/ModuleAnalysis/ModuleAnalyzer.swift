//
//  ModuleAnalyzer.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/7/24.
//

import TalkTalkSyntax

public struct ModuleAnalyzer {
	let name: String
	let files: [ParsedSourceFile]

	public init(name: String, files: [ParsedSourceFile]) {
		self.name = name
		self.files = files
	}

	public func analyze() throws -> AnalysisModule {
		var analysisModule = AnalysisModule(name: name, files: files)
		let environment = Environment(isModuleScope: true)

		// Find all the top level stuff this module has to offer
		for file in files {
			analysisModule.globals.merge(
				// TODO: Actually handle case where names clash
				try analyze(file: file, in: environment),
				uniquingKeysWith: { $1 }
			)
		}

		// Mark any found bindings as global
		for binding in environment.bindings {
			binding.isGlobal = true
		}

		// Do a second pass so things that were defined in other files can
		// get picked up. TODO: There's gotta be a better way.
		for file in files {
			analysisModule.globals.merge(
				try analyze(file: file, in: environment),
				uniquingKeysWith: { $1 }
			)
		}

		return analysisModule
	}

	// Get the top level stuff from this file since that's where globals live.
	private func analyze(file: ParsedSourceFile, in environment: Environment) throws -> [String: ModuleGlobal] {
		var result: [String: ModuleGlobal] = [:]
		let visitor = SourceFileAnalyzer()

		// Do a first pass over the file to find everything
		for syntax in file.syntax {
			let analyzed = try analyze(syntax: syntax, visitor: visitor, in: environment)

			// TODO: Handle case where names clash
			result.merge(analyzed, uniquingKeysWith: { $1 })
		}

		return result
	}

	private func analyze(syntax: any Syntax, visitor: SourceFileAnalyzer, in environment: Environment) throws -> [String: ModuleGlobal] {
		var result: [String: ModuleGlobal] = [:]

		switch syntax {
		case let syntax as FuncExpr:
			// Named functions get added as globals at the top level
			if let name = syntax.name {
				let analyzed = try visitor.visit(syntax, environment)
				result[name.lexeme] = ModuleGlobal(name: name.lexeme, syntax: syntax, type: analyzed.type)
			}
		case let syntax as DefExpr:
			// Def exprs also get added as globals at the top level
			let analyzed = try visitor.visit(syntax, environment)
			result[syntax.name.lexeme] = ModuleGlobal(name: syntax.name.lexeme, syntax: syntax, type: analyzed.type)
		default:
			()
		}

		return result
	}
}
