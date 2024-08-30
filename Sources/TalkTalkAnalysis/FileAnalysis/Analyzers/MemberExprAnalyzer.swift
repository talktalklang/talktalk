//
//  MemberExprAnalyzer.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/23/24.
//

import TalkTalkSyntax

struct MemberExprAnalyzer: Analyzer {
	let expr: any MemberExpr
	let visitor: SourceFileAnalyzer
	let context: Environment

	func analyze() throws -> any AnalyzedSyntax {
		let receiver = try expr.receiver.accept(visitor, context)
		let propertyName = expr.property
		let type = context.inferenceContext.lookup(syntax: expr)!

		return AnalyzedMemberExpr(
			inferenceType: type,
			wrapped: expr.cast(MemberExprSyntax.self),
			environment: context,
			receiverAnalyzed: receiver as! any AnalyzedExpr,
			memberAnalyzed: error(at: expr, "no member found", environment: context, expectation: .member),
			analysisErrors: [],
			isMutable: true
		)
	}
}
