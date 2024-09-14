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
		let type = context.inferenceContext.lookup(syntax: expr)

		// If it's an enum case we want to return a different syntax expression...
		if case let .enumCase(enumCase) = type,
		   let enumBinding = context.lookup(enumCase.typeName),
		   case let .enumType(enumType) = enumBinding.type,
		   let kase = enumType.cases.enumerated().first(where: { $0.element.name == expr.property })
		{
			return try AnalyzedEnumMemberExpr(
				wrapped: cast(expr, to: MemberExprSyntax.self),
				propertyAnalyzed: expr.property,
				paramsAnalyzed: kase.element.attachedTypes,
				inferenceType: .enumCase(kase.element),
				environment: context
			)
		}

		guard let receiver = try expr.receiver?.accept(visitor, context) else {
			return error(at: expr, "Could not determine receiver", environment: context)
		}

		let propertyName = expr.property

		// ...otherwise treat it as a struct member
		var member: (any Member)? = nil
		if let scope = context.getLexicalScope()?.scope {
			member = (scope.methods[propertyName] ?? scope.properties[propertyName])
		}

		if case let .structInstance(instance) = receiver.typeAnalyzed,
		   let structType = try context.lookupStruct(named: instance.type.name)
		{
			member = (structType.methods[propertyName] ?? structType.properties[propertyName])
		}

		guard let member else {
			return try AnalyzedMemberExpr(
				inferenceType: type ?? .any,
				wrapped: expr.cast(MemberExprSyntax.self),
				environment: context,
				receiverAnalyzed: castToAnyAnalyzedExpr(receiver),
				memberAnalyzed: error(at: expr, "no member found", environment: context, expectation: .member),
				analysisErrors: [],
				isMutable: true
			)
		}

		return try AnalyzedMemberExpr(
			inferenceType: type ?? .any,
			wrapped: expr.cast(MemberExprSyntax.self),
			environment: context,
			receiverAnalyzed: castToAnyAnalyzedExpr(receiver),
			memberAnalyzed: member,
			analysisErrors: [],
			isMutable: member.isMutable
		)
	}
}
