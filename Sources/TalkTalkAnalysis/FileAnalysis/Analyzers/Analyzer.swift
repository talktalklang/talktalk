//
//  Analyzer.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/23/24.
//

import TalkTalkCore
import TypeChecker

public protocol Analyzer {}

extension Analyzer {
	func castToAnyAnalyzedExpr(_ syntax: any Syntax, in context: Environment) throws -> any AnalyzedExpr {
		if let syntax = syntax as? any AnalyzedExpr {
			return syntax
		} else {
			return error(at: syntax, "Could not cast \(syntax) to any AnalyzedExpr", environment: context)
		}
	}

	func checkMutability(of receiver: any Syntax, in env: Environment) -> [AnalysisError] {
		switch receiver {
		case let receiver as any VarExpr:
			if let binding = env.lookup(receiver.name), !binding.isMutable {
				return [AnalysisError(kind: .cannotReassignLet(variable: receiver), location: receiver.location)]
			}
		default:
			()
		}

		return []
	}

	func errors(for syntax: any Syntax, in context: Context) -> [AnalysisError] {
		var errors: [AnalysisError] = []
		for error in context.diagnostics {
			if syntax.location.contains(error.location) {
				errors.append(
					.init(
						kind: .unknownError(error.message),
						location: error.location
					)
				)
			}
		}
		return errors
	}

	func castError<T>(at syntax: any Syntax, type: T.Type, in context: Environment) -> AnalyzedErrorSyntax {
		return error(at: syntax, "Could not cast \(syntax) to \(T.self)", environment: context)
	}

	func error(
		at expr: any Syntax, _ message: String, environment: Environment, expectation: ParseExpectation = .none
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
