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

		let inferenceType = try context.inferenceContext.get(expr)

		var getSymbol: Symbol? = nil
		var setSymbol: Symbol? = nil
		switch receiver.inferenceType {
		case let .type(type):
			if let member = type.member(named: "get"), case let .function(params, _) = context.inferenceContext.apply(member) {
				getSymbol = .method(type.module, type.name, "get", params.map(\.mangled))
			}

			if let member = type.member(named: "set"), case let .function(params, _) = context.inferenceContext.apply(member) {
				setSymbol = .method(type.module, type.name, "set", params.map(\.mangled))
			}
		case let .instance(instance):
			if let member = instance.member(named: "get"), case let .function(params, _) = context.inferenceContext.apply(member) {
				getSymbol = .method(instance.type.module, instance.type.name, "get", params.map(\.mangled))
			}

			if let member = instance.member(named: "set"), case let .function(params, _) = context.inferenceContext.apply(member) {
				setSymbol = .method(instance.type.module, instance.type.name, "set", params.map(\.mangled))
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
