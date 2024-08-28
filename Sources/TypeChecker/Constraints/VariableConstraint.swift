//
//  VariableConstraint.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/27/24.
//

import TalkTalkSyntax

struct VariableConstraint: Constraint {
	let typeVar: InferenceType
	let value: InferenceResult
	let location: SourceLocation

	func solve(in context: InferenceContext) -> ConstraintCheckResult {
		switch value {
		case .type(let type):
			context.unify(typeVar, type)
		case .scheme(let scheme):
			let type = context.instantiate(scheme: scheme)
			context.unify(typeVar, type)
		}

		return .ok
	}
}
