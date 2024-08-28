//
//  TypeParameterConstraint.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/27/24.
//

import TalkTalkSyntax

struct TypeParameterConstraint: Constraint {
	var owner: InferenceType
	var parameter: InferenceType

	var location: SourceLocation
	
	func solve(in context: InferenceContext) -> ConstraintCheckResult {
		.ok
	}
}
