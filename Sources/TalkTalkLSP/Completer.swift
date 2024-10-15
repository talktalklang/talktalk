//
//  Completer.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/26/24.
//

import TalkTalkAnalysis
import TalkTalkCore
import TalkTalkCore
import TypeChecker

actor Completer {
	var source: SourceFile
	var lastSuccessfulExprs: [any AnalyzedSyntax] = []

	public init(source: SourceFile) async {
		self.source = source
		parse()
	}

	public func update(text: String) {
		source = SourceFile(path: source.path, text: text)
		parse()
	}

	func parse() {
		let lexer = Lexer(source)
		var parser = Parser(lexer)
		let parsed = parser.parse()

		do {
			let context = try Typer(module: "", imports: []).solve(parsed)
			let environment = Environment(inferenceContext: context, symbolGenerator: .init(moduleName: "Completer", parent: nil)) // TODO: use module environment
			let analyzed = try SourceFileAnalyzer.analyze(parsed, in: environment)
			lastSuccessfulExprs = analyzed
		} catch {
			Log.error("Error analyzing: \(error)")
		}
	}
}
