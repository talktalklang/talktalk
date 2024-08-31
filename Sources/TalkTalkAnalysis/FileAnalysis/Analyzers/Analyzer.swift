//
//  Analyzer.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/23/24.
//

import TalkTalkSyntax
import TypeChecker

public protocol Analyzer {}

extension Analyzer {
	func checkMutability(of receiver: any Typed, in env: Environment) -> [AnalysisError] {
		[]
	}

	func errors(for syntax: any Syntax, in context: InferenceContext) -> [AnalysisError] {
		var errors: [AnalysisError] = []
		for error in context.errors {
			if syntax.location.contains(error.location) {
				let kind: AnalysisErrorKind = switch error.kind {
				case let .argumentError(expected: expected, actual: actual):
					.argumentError(expected: expected, received: actual)
				case let .memberNotFound(type, name):
					.noMemberFound(receiver: syntax, property: name)
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
		return errors
	}

	func error(
		at expr: any Syntax, _ message: String, environment: Environment, expectation: ParseExpectation
	) -> AnalyzedErrorSyntax {
		AnalyzedErrorSyntax(
			typeID: .error(
				.init(
					kind: .unknownError(message),
					location: expr.location
				)
			),
			wrapped: ParseErrorSyntax(location: expr.location, message: message, expectation: expectation),
			environment: environment
		)
	}
}
