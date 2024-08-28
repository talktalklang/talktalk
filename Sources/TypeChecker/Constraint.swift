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
	var location: SourceLocation { get }

	func solve(in context: InferenceContext) -> ConstraintCheckResult
}
