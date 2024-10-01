//
//  VariableConstraint.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/27/24.
//

import TalkTalkCore

struct VariableConstraint: InferenceConstraint {
	let typeVar: InferenceType
	let value: InferenceResult
	let location: SourceLocation

	func result(in context: InferenceContext) -> String {
		let typeVar = context.applySubstitutions(to: typeVar)
		let value = context.applySubstitutions(to: value.asType(in: context))
		return "VariableConstraint(typeVar: \(typeVar.debugDescription), value: \(value.debugDescription))"
	}

	var description: String {
		"VariableConstraint(typeVar: \(typeVar.debugDescription), value: \(value.debugDescription))"
	}

	func solve(in context: InferenceContext) -> ConstraintCheckResult {
		switch value {
		case let .type(type):
			context.unify(typeVar, type, location)
		case let .scheme(scheme):
			let type = context.instantiate(scheme: scheme)
			context.unify(typeVar, type, location)
		}

		return .ok
	}
}
