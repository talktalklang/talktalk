//
//  EqualityConstraint.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/27/24.
//

import TalkTalkSyntax

struct EqualityConstraint: Constraint {
	let lhs: InferenceResult
	let rhs: InferenceResult
	let location: SourceLocation

	func result(in context: InferenceContext) -> String {
		let lhs = context.applySubstitutions(to: lhs.asType(in: context))
		let rhs = context.applySubstitutions(to: rhs.asType(in: context))

		return "EqualityConstraint(lhs: \(lhs), rhs: \(rhs))"
	}

	var description: String {
		"EqualityConstraint(lhs: \(lhs), rhs: \(rhs))"
	}

	func solve(in context: InferenceContext) -> ConstraintCheckResult {
		let lhs = switch lhs {
		case .scheme(let scheme):
			context.applySubstitutions(to: context.instantiate(scheme: scheme))
		case .type(let type):
			context.applySubstitutions(to: type)
		}

		let rhs = switch rhs {
		case .scheme(let scheme):
			context.applySubstitutions(to: context.instantiate(scheme: scheme))
		case .type(let type):
			context.applySubstitutions(to: type)
		}

		if lhs == rhs {
			return .ok
		}

		if case .typeVar(let leftVar) = lhs {
			context.bind(typeVar: leftVar, to: context.applySubstitutions(to: rhs))
			return .ok
		}

		if case .typeVar(let rightVar) = rhs {
			context.bind(typeVar: rightVar, to: context.applySubstitutions(to: lhs))
			return .ok
		}

		return .error([Diagnostic(
			message: "Type mismatch: expected \(rhs), but got \(lhs)",
			severity: .error,
			location: location
		)])
	}
}

extension Constraint where Self == EqualityConstraint {
	static func equality(
		_ lhs: InferenceResult,
		_ rhs: InferenceResult,
		at location: SourceLocation
	) -> EqualityConstraint {
		EqualityConstraint(lhs: lhs, rhs: rhs, location: location)
	}

	static func equality(
		_ lhs: InferenceType,
		_ rhs: InferenceType,
		at location: SourceLocation
	) -> EqualityConstraint {
		EqualityConstraint(lhs: .type(lhs), rhs: .type(rhs), location: location)
	}
}
