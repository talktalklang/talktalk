//
//  Completer.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/26/24.
//

import TalkTalkAnalysis
import TalkTalkSyntax

class Completer {
	var source: String
	var lastSuccessfulExprs: [any AnalyzedSyntax] = []

	public init(source: String) {
		self.source = source
		parse()
	}

	func parse() {
		let lexer = TalkTalkLexer(source)
		var parser = Parser(lexer)
		let parsed = parser.parse()

		do {
			let environment: Environment = .init() // TODO: use module environment
			let analyzed = try SourceFileAnalyzer.analyze(parsed, in: environment)
			lastSuccessfulExprs = analyzed
		} catch {
			Log.error("Error analyzing: \(error)")
		}
	}

	func matching(position: Position, exprs: [any AnalyzedSyntax]) -> [any AnalyzedSyntax] {
		var result: [any AnalyzedSyntax] = []
		for expr in exprs {
			if expr.location.contains(position) {
				result.append(expr)
			}

			result.append(contentsOf: matching(position: position, exprs: expr.analyzedChildren))
		}

		return result
	}

	public func completions(from request: TextDocumentCompletionRequest) throws -> [CompletionItem] {
		if let char = request.context.triggerCharacter, char == "." {
			return dotCompletions(at: request.position)
		}

		return localCompletions(at: request.position)
	}

	func dotCompletions(at position: Position) -> [CompletionItem] {
		var result: [CompletionItem] = []
		let matches = matching(position: position, exprs: lastSuccessfulExprs)

		// Try to figure out the receiver of the member access
		for match in matches {
			guard let match = match as? AnalyzedExprStmt,
						let memberExpr = match.exprAnalyzed as? AnalyzedMemberExpr,
						case let .instance(instance) = memberExpr.receiverAnalyzed.typeID.current,
						case let .struct(name) = instance.ofType,
						let structType = match.environment.lookupStruct(named: name) else {
				continue
			}

			result.append(contentsOf: structType.properties.reduce(into: []) { res, prop in
				if prop.key.starts(with: memberExpr.property) {
					res.append(.init(label: prop.key, kind: .property))
				}
			})

			result.append(contentsOf: structType.methods.reduce(into: []) { res, prop in
				if prop.key.starts(with: memberExpr.property), prop.key != "init" {
					res.append(.init(label: prop.key, kind: .method))
				}
			})
		}

		return result
	}

	func localCompletions(at position: Position) -> [CompletionItem] {
		var result: [CompletionItem] = []
		let matches = matching(position: position, exprs: lastSuccessfulExprs)

		for match in matches {
			if let errorSyntax = match.as(AnalyzedErrorSyntax.self) {
				let text = errorSyntax.location.start.lexeme
				for binding in errorSyntax.environment.allBindings() {
					if binding.name.starts(with: text) {
						let kind: CompletionItemKind = switch binding.type.type() {
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
