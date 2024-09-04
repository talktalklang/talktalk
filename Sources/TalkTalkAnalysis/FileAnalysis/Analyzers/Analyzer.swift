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
	func castToAnyAnalyzedExpr(_ syntax: any Syntax) throws -> any AnalyzedExpr {
		if let syntax = syntax as? any AnalyzedExpr {
			return syntax
		} else {
			throw AnalyzerError.unexpectedCast(expected: "any AnalyzedExpr", received: "\(syntax)")
		}
	}

	func cast<T>(_ syntax: any Syntax, to type: T.Type) throws -> T {
		if let syntax = syntax as? T {
			return syntax
		} else {
			throw AnalyzerError.unexpectedCast(expected: "\(T.self)", received: "\(syntax)")
		}
	}

	func cast<T>(_ syntax: [any Syntax], to type: T.Type) throws -> T {
		if let syntax = syntax as? T {
			return syntax
		} else {
			throw AnalyzerError.unexpectedCast(expected: "\(T.self)", received: "\(syntax)")
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

	func errors(for syntax: any Syntax, in context: InferenceContext) -> [AnalysisError] {
		var errors: [AnalysisError] = []
		for error in context.errors {
			if syntax.location.contains(error.location) {
				errors.append(
					.init(
						kind: .inferenceError(error.kind),
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
