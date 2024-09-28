//
//  SubscriptExprAnalyzer.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/24/24.
//

import TalkTalkBytecode
import TalkTalkCore

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

		let getSymbol: Symbol
		switch receiver.inferenceType {
		case let .instance(instanceType):
			let type = instanceType.type
			getSymbol = .method(type.context.moduleName, type.name, "get", args.map(\.inferenceType.mangled))
		default:
			return error(at: expr, "Could not determine get() method for \(receiver.inferenceType)", environment: context)
		}

		return try AnalyzedSubscriptExpr(
			receiverAnalyzed: castToAnyAnalyzedExpr(receiver),
			argsAnalyzed: args,
			getSymbol: getSymbol,
			wrapped: cast(expr, to: SubscriptExprSyntax.self),
			inferenceType: inferenceType,
			environment: context,
			analysisErrors: []
		)
	}
}
