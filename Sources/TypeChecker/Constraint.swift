//
//  Constraint.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/25/24.
//
import TalkTalkSyntax

enum ConstraintCheckResult {
	case ok, error([Diagnostic])
}

protocol Constraint {
	func solve(in context: InferenceContext) -> ConstraintCheckResult
}
