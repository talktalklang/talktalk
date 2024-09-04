//
//  CallExprAnalyzer.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/23/24.
//

import TalkTalkSyntax

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
			AnalyzedArgument(
				environment: context,
				label: $0.label,
				wrapped: $0,
				expr: try castToAnyAnalyzedExpr($0.value.accept(visitor, context))
			)
		}

		// How many arguments are expected to be passed to this call
		let type = context.inferenceContext.lookup(syntax: expr)

		for error in context.inferenceContext.errors {
			errors.append(
				.init(
					kind: .inferenceError(error.kind),
					location: error.location
				)
			)
		}

		return AnalyzedCallExpr(
			inferenceType: type ?? .any,
			wrapped: expr.cast(CallExprSyntax.self),
			calleeAnalyzed: try castToAnyAnalyzedExpr(callee),
			argsAnalyzed: args,
			analysisErrors: errors,
			environment: context
		)
	}
}
