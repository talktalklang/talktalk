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
		let type = context.inferenceContext.lookup(syntax: expr)

		var member: (any Member)? = nil
		if let scope = context.getLexicalScope()?.scope {
			member = (scope.methods[propertyName] ?? scope.properties[propertyName])
		}

		if case let .structInstance(instance) = receiver.typeAnalyzed,
			 let structType = context.lookupStruct(named: instance.type.name) {
			member = (structType.methods[propertyName] ?? structType.properties[propertyName])
		}

		guard let member else {
			return AnalyzedMemberExpr(
				inferenceType: type ?? .any,
				wrapped: expr.cast(MemberExprSyntax.self),
				environment: context,
				receiverAnalyzed: try castToAnyAnalyzedExpr(receiver),
				memberAnalyzed: error(at: expr, "no member found", environment: context, expectation: .member),
				analysisErrors: [],
				isMutable: true
			)
		}

		return AnalyzedMemberExpr(
			inferenceType: type ?? .any,
			wrapped: expr.cast(MemberExprSyntax.self),
			environment: context,
			receiverAnalyzed: try castToAnyAnalyzedExpr(receiver),
			memberAnalyzed: member,
			analysisErrors: [],
			isMutable: member.isMutable
		)
	}
}
