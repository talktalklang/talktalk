//
//  Analyzer.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/23/24.
//

import TalkTalkSyntax

public protocol Analyzer {}

extension Analyzer {
	func infer(_ exprs: [any AnalyzedExpr], in env: Environment) {
		let type = exprs.map(\.typeID.current).max(by: { $0.specificity < $1.specificity }) ?? .placeholder

		for var expr in exprs {
			if let exprStmt = expr as? AnalyzedExprStmt {
				// Unwrap expr stmt
				expr = exprStmt.exprAnalyzed
			}

			if let expr = expr as? AnalyzedVarExpr {
				expr.typeID.update(type, location: expr.location)
				env.update(local: expr.name, as: type)
				if let capture = env.captures.first(where: { $0.name == expr.name }) {
					capture.binding.type.update(type, location: expr.location)
				}
			}
		}
	}

	func checkAssignment(
		to receiver: any Typed,
		value: any AnalyzedExpr,
		in env: Environment
	) -> [AnalysisError] {
		var errors: [AnalysisError] = []

		if !env.shouldReportErrors {
			return errors
		}

		errors.append(contentsOf: checkMutability(of: receiver, in: env))

		if value.typeID.current == .placeholder {
			value.typeID.update(receiver.typeID.current, location: value.location)
		}

		if receiver.typeID.current.isAssignable(from: value.typeAnalyzed) {
			receiver.typeID.update(value.typeID.current, location: value.location)
			return errors
		}

		errors.append(
			AnalysisError(
				kind: .typeCannotAssign(
					expected: receiver.typeID,
					received: value.typeID
				),
				location: value.location
			)
		)

		return errors
	}

	func checkMutability(of receiver: any Typed, in env: Environment) -> [AnalysisError] {
		switch receiver {
		case let receiver as AnalyzedVarExpr:
			let binding = env.lookup(receiver.name)

			if !receiver.isMutable || (binding?.isMutable == false) {
				return [
					AnalysisError(
						kind: .cannotReassignLet(variable: receiver),
						location: receiver.location
					),
				]
			}
		case let receiver as AnalyzedMemberExpr:
			if !receiver.isMutable {
				return [AnalysisError(
					kind: .cannotReassignLet(variable: receiver),
					location: receiver.location
				)]
			}
		default:
			()
		}

		return []
	}

	func error(
		at expr: any Syntax, _ message: String, environment: Environment, expectation: ParseExpectation
	) -> AnalyzedErrorSyntax {
		AnalyzedErrorSyntax(
			typeID: TypeID(.error(message)),
			wrapped: ParseErrorSyntax(location: expr.location, message: message, expectation: expectation),
			environment: environment
		)
	}
}
