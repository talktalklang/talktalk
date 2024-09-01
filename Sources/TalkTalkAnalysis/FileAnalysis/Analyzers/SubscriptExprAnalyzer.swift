//
//  SubscriptExprAnalyzer.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/24/24.
//

import TalkTalkSyntax

struct SubscriptExprAnalyzer {
	let expr: any SubscriptExpr
	let visitor: SourceFileAnalyzer
	let context: Environment

	func analyze() throws -> any AnalyzedSyntax {
		let receiver = try expr.receiver.accept(visitor, context) as! any AnalyzedExpr
		let args = try expr.args.map { try $0.accept(visitor, context) } as! [AnalyzedArgument]

		var result = AnalyzedSubscriptExpr(
			receiverAnalyzed: receiver,
			argsAnalyzed: args,
			wrapped: expr as! SubscriptExprSyntax,
			inferenceType: context.inferenceContext.lookup(syntax: expr)!,
			environment: context,
			analysisErrors: []
		)

		return result
	}
}
