//
//  SubscriptExprAnalyzer.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/24/24.
//

import TalkTalkSyntax

struct SubscriptExprAnalyzer: Analyzer {
	let expr: any SubscriptExpr
	let visitor: SourceFileAnalyzer
	let context: Environment

	func analyze() throws -> any AnalyzedSyntax {
		let receiver = try expr.receiver.accept(visitor, context)
		let args = try cast(expr.args.map { try $0.accept(visitor, context) }, to: [AnalyzedArgument].self)

		guard let inferenceType = context.inferenceContext.lookup(syntax: expr) else {
			throw AnalyzerError.typeNotInferred("\(expr.description)")
		}

		return try AnalyzedSubscriptExpr(
			receiverAnalyzed: castToAnyAnalyzedExpr(receiver),
			argsAnalyzed: args,
			wrapped: cast(expr, to: SubscriptExprSyntax.self),
			inferenceType: inferenceType,
			environment: context,
			analysisErrors: []
		)
	}
}
