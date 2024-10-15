//
//  MemberExprAnalyzer.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/23/24.
//

import TalkTalkBytecode
import TalkTalkCore
import TypeChecker

struct MemberExprAnalyzer: Analyzer {
	let expr: any MemberExpr
	let visitor: SourceFileAnalyzer
	let context: Environment

	func analyze() throws -> any AnalyzedSyntax {
		let type = try context.inferenceContext.get(expr)

		// If it's an enum case we want to return a different syntax expression...
		if case let .type(.enumCase(enumCase)) = type,
		   let kase = enumCase.type.cases[expr.property]
		{
			guard let expr = expr as? MemberExprSyntax else {
				return error(at: expr, "Could not cast \(expr) to MemberExprSyntax", environment: context)
			}

			return AnalyzedEnumMemberExpr(
				wrapped: expr,
				propertyAnalyzed: expr.property,
				paramsAnalyzed: kase.attachedTypes.map { context.inferenceContext.apply($0) },
				inferenceType: .type(.enumCase(kase)),
				environment: context
			)
		}

		if case let .type(.enum(enumType)) = type,
			 let kase = enumType.cases[expr.property]
		{
			guard let expr = expr as? MemberExprSyntax else {
				return error(at: expr, "Could not cast \(expr) to MemberExprSyntax", environment: context)
			}

			return AnalyzedEnumMemberExpr(
				wrapped: expr,
				propertyAnalyzed: expr.property,
				paramsAnalyzed: kase.attachedTypes.map { context.inferenceContext.apply($0) },
				inferenceType: .type(.enumCase(kase)),
				environment: context
			)
		}

		guard let receiver = try expr.receiver?.accept(visitor, context) else {
			return error(at: expr, "Could not determine receiver", environment: context)
		}

		let propertyName = expr.property
		var analysisDefinition: Definition? = nil

		return try AnalyzedMemberExpr(
			inferenceType: type,
			wrapped: expr.cast(MemberExprSyntax.self),
			environment: context,
			receiverAnalyzed: castToAnyAnalyzedExpr(receiver, in: context),
			memberSymbol: .value("WIP", "WIP"),
			analysisErrors: [],
			analysisDefinition: analysisDefinition,
			isMutable: false
		)
	}
}
