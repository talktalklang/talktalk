//
//  Completer.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/26/24.
//

import TalkTalkAnalysis
import TalkTalkSyntax

struct Completer: AnalyzedVisitor {
	var source: String
	var lastSuccessfulExprs: [any AnalyzedExpr] = []

	public init(source: String) {
		self.source = source
		parse()
	}

	mutating func parse() {
		let lexer = TalkTalkLexer(source)
		var parser = Parser(lexer)
		let parsed = parser.parse()

		do {
			let analyzed = try Analyzer.analyze(parsed)
			lastSuccessfulExprs = [analyzed]
		} catch {
			Log.error("Error analyzing: \(error)")
		}
	}

	func matching(position: Position, exprs: [any AnalyzedExpr]) -> [any AnalyzedExpr] {
		var result: [any AnalyzedExpr] = []
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

		Log.info("completions matches: \(matches) out of \(lastSuccessfulExprs)")

		for match in matches {
			Log.info("match: \(match)")
			if let errorSyntax = match.as(AnalyzedErrorSyntax.self) {
				let text = errorSyntax.location.start.lexeme

				Log.info("text: \(text)")

				for binding in errorSyntax.environment.bindings {
					if binding.name.starts(with: text) {
						let kind: CompletionItemKind = switch binding.type {
						case .function(let string, let valueType, let analyzedParamsExpr, let array):
							.function
						case .struct(let structType):
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

	// MARK: Visitor stuff

	public typealias Value = Void
	public class Context {
		var results: [CompletionItem] = []
	}

	public func visit(_ expr: AnalyzedIdentifierExpr, _ context: Context) throws {}

	public func visit(_ expr: AnalyzedCallExpr, _ context: Context) throws -> Value {}

	public func visit(_ expr: AnalyzedDefExpr, _ context: Context) throws -> Value {}

	public func visit(_ expr: AnalyzedErrorSyntax, _ context: Context) throws -> Value {}

	public func visit(_ expr: AnalyzedLiteralExpr, _ context: Context) throws -> Value {}

	public func visit(_ expr: AnalyzedVarExpr, _ context: Context) throws -> Value {}

	public func visit(_ expr: AnalyzedBinaryExpr, _ context: Context) throws -> Value {}

	public func visit(_ expr: AnalyzedUnaryExpr, _ context: Context) throws -> Value {}

	public func visit(_ expr: AnalyzedIfExpr, _ context: Context) throws -> Value {}

	public func visit(_ expr: AnalyzedFuncExpr, _ context: Context) throws -> Value {}

	public func visit(_ expr: AnalyzedBlockExpr, _ context: Context) throws -> Value {}

	public func visit(_ expr: AnalyzedWhileExpr, _ context: Context) throws -> Value {}

	public func visit(_ expr: AnalyzedParamsExpr, _ context: Context) throws -> Value {}

	public func visit(_ expr: AnalyzedReturnExpr, _ context: Context) throws -> Value {}

	public func visit(_ expr: AnalyzedMemberExpr, _ context: Context) throws -> Value {}

	public func visit(_ expr: AnalyzedDeclBlock, _ context: Context) throws -> Value {}

	public func visit(_ expr: AnalyzedStructExpr, _ context: Context) throws -> Value {}

	public func visit(_ expr: AnalyzedVarDecl, _ context: Context) throws -> Value {}

	public func visit(_ expr: AnalyzedLetDecl, _ context: Context) throws -> Value {}
}
