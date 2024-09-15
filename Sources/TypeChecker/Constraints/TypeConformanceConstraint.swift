//
//  TypeConformanceConstraint.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/27/24.
//

import TalkTalkSyntax

struct TypeConformanceConstraint: Constraint {
	let type: InferenceType
	let conformsTo: InferenceType

	func result(in context: InferenceContext) -> String {
		let type = context.applySubstitutions(to: type)
		let conformsTo = context.applySubstitutions(to: conformsTo)
		return "TypeConformanceConstraint(type: \(type), conformsTo: \(conformsTo))"
	}

	var description: String {
		"TypeConformanceConstraint(type: \(type), conformsTo: \(conformsTo))"
	}

	var location: SourceLocation

	func solve(in _: InferenceContext) -> ConstraintCheckResult {
		.ok
	}
}
