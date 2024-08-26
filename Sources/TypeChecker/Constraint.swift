//
//  Constraint.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/25/24.
//

enum ConstraintCheckResult {
	case ok(InferenceType), error(InferenceError)
}

protocol Constraint {
	var type: ConstraintType { get }

	func check(_ type: InferenceType, with args: [InferenceType]) -> ConstraintCheckResult
}
