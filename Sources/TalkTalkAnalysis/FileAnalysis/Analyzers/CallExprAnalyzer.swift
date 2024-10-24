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
				expr: castToAnyAnalyzedExpr($0.value.accept(visitor, context), in: context)
			)
		}

		// How many arguments are expected to be passed to this call
		let type = context.type(for: expr)

		for error in context.inferenceContext.diagnostics {
			errors.append(
				.init(
					kind: .unknownError(error.message),
					location: error.location
				)
			)
		}

		return try AnalyzedCallExpr(
			inferenceType: type,
			wrapped: expr.cast(CallExprSyntax.self),
			calleeAnalyzed: castToAnyAnalyzedExpr(callee, in: context),
			argsAnalyzed: args,
			analysisErrors: errors,
			environment: context
		)
	}
}
