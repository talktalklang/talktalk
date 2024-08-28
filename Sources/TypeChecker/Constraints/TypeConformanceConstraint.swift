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

	var location: SourceLocation

	func solve(in context: InferenceContext) -> ConstraintCheckResult {
		.ok
	}
}
