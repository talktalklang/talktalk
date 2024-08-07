//
//  Completer.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/26/24.
//

import TalkTalkAnalysis
import TalkTalkSyntax

struct Completer {
	var source: String
	var lastSuccessfulExprs: [any AnalyzedSyntax] = []

	public init(source: String) {
		self.source = source
		parse()
	}

	mutating func parse() {
		let lexer = TalkTalkLexer(source)
		var parser = Parser(lexer)
		let parsed = parser.parse()

		do {
			let environment: Environment = .init() // TODO: use module environment
			let analyzed = try SourceFileAnalyzer.analyze(parsed, in: environment)
			lastSuccessfulExprs = [analyzed]
		} catch {
			Log.error("Error analyzing: \(error)")
		}
	}

	func matching(position: Position, exprs: [any AnalyzedSyntax]) -> [any AnalyzedSyntax] {
		var result: [any AnalyzedSyntax] = []
		for expr in exprs {
			if expr.location.contains(position) {
				result.append(expr)
			} else {
				Log.info("\(expr.description) does not include \(position)")
			}

			result.append(contentsOf: matching(position: position, exprs: expr.analyzedChildren))
		}

		return result
	}

	public func completions(at position: Position) throws -> [CompletionItem] {
		var result: [CompletionItem] = []
		let matches = matching(position: position, exprs: lastSuccessfulExprs)

		for match in matches {
			if let errorSyntax = match.as(AnalyzedErrorSyntax.self) {
				let text = errorSyntax.location.start.lexeme
				for binding in errorSyntax.environment.bindings {
					if binding.name.starts(with: text) {
						let kind: CompletionItemKind = switch binding.type {
						case .function(_, _, _, _):
							.function
						case .struct(_):
							.constant
						default:
							.variable
						}

						result.append(CompletionItem(label: binding.name, kind: kind))
					}
				}
			}
		}

		return result
	}
}
