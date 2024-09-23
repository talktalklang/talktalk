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

		return "EqualityConstraint(lhs: \(lhs.debugDescription), rhs: \(rhs.debugDescription))"
	}

	var description: String {
		"EqualityConstraint(lhs: \(lhs.debugDescription), rhs: \(rhs.debugDescription))"
	}

	func solve(in context: InferenceContext) -> ConstraintCheckResult {
		let lhs = switch lhs {
		case let .scheme(scheme):
			context.applySubstitutions(to: context.instantiate(scheme: scheme))
		case let .type(type):
			context.applySubstitutions(to: type)
		}

		let rhs = switch rhs {
		case let .scheme(scheme):
			context.applySubstitutions(to: context.instantiate(scheme: scheme))
		case let .type(type):
			context.applySubstitutions(to: type)
		}

		if lhs == rhs {
			return .ok
		}

		context.unify(lhs, rhs, location)

		return .ok
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
