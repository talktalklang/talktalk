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
			try AnalyzedArgument(
				environment: context,
				label: $0.label,
				wrapped: $0,
				expr: $0.value.accept(visitor, context) as! any AnalyzedExpr
			)
		}

		// How many arguments are expected to be passed to this call
		let type = context.inferenceContext.lookup(syntax: expr)

		for error in context.inferenceContext.errors {
			if expr.location.contains(error.location) {
				let kind: AnalysisErrorKind = switch error.kind {
				case let .argumentError(expected: expected, actual: actual):
					.argumentError(expected: expected, received: actual)
				case let .memberNotFound(_, name):
					.noMemberFound(receiver: expr, property: name)
				default:
					.unknownError("\(error.kind)")
				}

				errors.append(
					.init(
						kind: kind,
						location: error.location
					)
				)
			}
		}

		return AnalyzedCallExpr(
			inferenceType: type!,
			wrapped: expr.cast(CallExprSyntax.self),
			calleeAnalyzed: callee as! any AnalyzedExpr,
			argsAnalyzed: args,
			analysisErrors: errors,
			environment: context
		)
	}
}
