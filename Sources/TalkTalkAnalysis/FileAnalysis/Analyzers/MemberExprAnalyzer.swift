//
//  MemberExprAnalyzer.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/23/24.
//

import TalkTalkSyntax
import TypeChecker

struct MemberExprAnalyzer: Analyzer {
	let expr: any MemberExpr
	let visitor: SourceFileAnalyzer
	let context: Environment

	func analyze() throws -> any AnalyzedSyntax {
		let type = context.inferenceContext.lookup(syntax: expr)

		// If it's an enum case we want to return a different syntax expression...
		if case let .enumCase(enumCase) = type,
		   let kase = enumCase.type.cases.enumerated().first(where: { $0.element.name == expr.property })
		{
			return try AnalyzedEnumMemberExpr(
				wrapped: cast(expr, to: MemberExprSyntax.self),
				propertyAnalyzed: expr.property,
				paramsAnalyzed: kase.element.attachedTypes,
				inferenceType: .enumCase(kase.element),
				environment: context
			)
		}

		if case let .instantiatable(.enumType(enumType)) = type,
		   let kase = enumType.cases.first(where: { $0.name == expr.property })
		{
			return try AnalyzedEnumMemberExpr(
				wrapped: cast(expr, to: MemberExprSyntax.self),
				propertyAnalyzed: expr.property,
				paramsAnalyzed: kase.attachedTypes,
				inferenceType: .enumCase(kase),
				environment: context
			)
		}

		guard let receiver = try expr.receiver?.accept(visitor, context) else {
			return error(at: expr, "Could not determine receiver", environment: context)
		}

		let propertyName = expr.property
		var member: (any Member)? = nil

		// If we have an existing lexical scope, use that
		if let scope = context.getLexicalScope() {
			member = (scope.methods[propertyName] ?? scope.properties[propertyName])
		}

		// If it's boxed, we create members
		if case let .instance(instance) = receiver.typeAnalyzed, instance.type is ProtocolType {
			guard let type = instance.member(named: propertyName, in: context.inferenceContext) else {
				return error(at: expr, "No member found for \(instance) named \(propertyName)", environment: context)
			}

			member = switch type {
			case let .function(params, returns):
				Method(
					name: propertyName,
					symbol: context.symbolGenerator.method(nil, propertyName, parameters: params.map(\.description), source: .internal),
					params: params,
					inferenceType: .function(params, returns),
					location: expr.location,
					returnTypeID: returns
				)
			default:
				Property(
					symbol: context.symbolGenerator.property(nil, propertyName, source: .internal),
					name: propertyName,
					// swiftlint:disable force_unwrapping
					inferenceType: type,
					// swiftlint:enable force_unwrapping
					location: expr.location,
					isMutable: false
				)
			}
		}

		if member == nil, case let .instance(instance) = receiver.typeAnalyzed {
			if let type = try context.type(named: instance.type.name) {
				member = (type.methods[propertyName] ?? type.properties[propertyName])
			}
		}

		if member == nil, case let .enumCase(enumCase) = receiver.typeAnalyzed {
			if let enumType = try context.type(named: enumCase.type.name) {
				member = enumType.methods[propertyName]
			}
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
