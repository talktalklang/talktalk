//
//  CallExprAnalyzer.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/23/24.
//

import TalkTalkCore

struct CallExprAnalyzer: Analyzer {
	enum CallExprError: Error, @unchecked Sendable {
		case structNotFound(AnalyzedErrorSyntax)
	}

	let expr: any CallExpr
	let visitor: SourceFileAnalyzer
	let context: Environment

	func analyze() throws -> any AnalyzedSyntax {
		let callee = try expr.callee.accept(visitor, context)
		var errors: [AnalysisError] = []

		let args = try expr.args.map {
			try AnalyzedArgument(
				environment: context,
				label: $0.label,
				wrapped: $0,
				expr: castToAnyAnalyzedExpr($0.value.accept(visitor, context))
			)
		}

		// How many arguments are expected to be passed to this call
		let type = context.type(for: expr)

		for error in context.inferenceContext.errors {
			errors.append(
				.init(
					kind: .inferenceError(error.kind),
					location: error.location
				)
			)
		}

		return try AnalyzedCallExpr(
			inferenceType: type,
			wrapped: expr.cast(CallExprSyntax.self),
			calleeAnalyzed: castToAnyAnalyzedExpr(callee),
			argsAnalyzed: args,
			analysisErrors: errors,
			environment: context
		)
	}
}
