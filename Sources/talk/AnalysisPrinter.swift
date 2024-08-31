//
//  AnalysisPrinter.swift
//
//
//  Created by Pat Nakajima on 7/11/24.
//

import ArgumentParser
import Foundation
import TalkTalkAnalysis
import TalkTalkSyntax
import TypeChecker

struct AnalysisPrinter: TalkTalkCommand {
	static let configuration = CommandConfiguration(
		commandName: "analysis",
		abstract: "Print the analysis for the given input"
	)

	@Argument(help: "The input to analyze.", completion: .file(extensions: [".tlk"]))
	var input: String

	func run() async throws {
		let source = try get(input: input)
		let parsed = try Parser.parse(source)
		let inferenceContext = Inferencer(imports: []).infer(parsed)
		let context = SourceFileAnalyzer.Context(inferenceContext: inferenceContext, symbolGenerator: .init(moduleName: "", parent: nil))
		let analyzed = try SourceFileAnalyzer.analyze(parsed, in: context)
		try print(TalkTalkAnalysis.AnalysisPrinter.format(analyzed))
	}
}
