//
//  UnwrapConstraint.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/29/24.
//
import TalkTalkCore

struct UnwrapConstraint: Constraint {
	let typeVar: InferenceType
	let location: SourceLocation
	var isRetry: Bool = false

	func result(in context: InferenceContext) -> String {
		let typeVar = context.applySubstitutions(to: typeVar)
		return "UnwrapConstraint(typeVar: \(typeVar.debugDescription))"
	}

	var description: String {
		"UnwrapConstraint(typeVar: \(typeVar.debugDescription))"
	}

	func solve(in context: InferenceContext) -> ConstraintCheckResult {
		let type = context.applySubstitutions(to: typeVar)

		if case let .optional(type) = type {
			context.unify(typeVar, type, location)
			return .ok
		} else if case .typeVar = type, !isRetry {
			context.deferConstraint(UnwrapConstraint(typeVar: type, location: location, isRetry: true))
			return .ok
		} else {
			return .error([
				.init(message: "Cannot unwrap non-optional type: \(type)", severity: .error, location: location)
			])
		}
	}
}
