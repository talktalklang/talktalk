//
//  SubscriptExprAnalyzer.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/24/24.
//

import TalkTalkBytecode
import TalkTalkCore

struct SubscriptExprAnalyzer: Analyzer {
	let expr: SubscriptExprSyntax
	let visitor: SourceFileAnalyzer
	let context: Environment

	func analyze() throws -> any AnalyzedSyntax {
		let receiver = try expr.receiver.accept(visitor, context)
		guard let args = try expr.args.map({ try $0.accept(visitor, context) }) as? [AnalyzedArgument] else {
			return castError(at: expr, type: [AnalyzedArgument].self, in: context)
		}

		guard let inferenceType = context.inferenceContext.lookup(syntax: expr) else {
			throw AnalyzerError.typeNotInferred("\(expr.description)")
		}

		var getSymbol: Symbol? = nil
		var setSymbol: Symbol? = nil
		switch receiver.inferenceType {
		case let .instanceV1(instance):
			if case let .function(params, _) = instance.genericMethod(named: "get") {
				getSymbol = .method(instance.type.context.moduleName, instance.type.name, "get", params.map(\.mangled))
			}

			if case let .function(params, _) = instance.genericMethod(named: "set") {
				setSymbol = .method(instance.type.context.moduleName, instance.type.name, "set", params.map(\.mangled))
			}
		default:
			return error(at: expr, "Could not determine get() method for \(receiver.inferenceType)", environment: context)
		}

		return try AnalyzedSubscriptExpr(
			receiverAnalyzed: castToAnyAnalyzedExpr(receiver, in: context),
			argsAnalyzed: args,
			getSymbol: getSymbol,
			setSymbol: setSymbol,
			wrapped: expr,
			inferenceType: inferenceType,
			environment: context,
			analysisErrors: []
		)
	}
}
