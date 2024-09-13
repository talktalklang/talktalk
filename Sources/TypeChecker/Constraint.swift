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

protocol Constraint: CustomStringConvertible {
	// Where in the original source was this constraint added
	var location: SourceLocation { get }

	// Actually performs the unification/solving of types
	func solve(in context: InferenceContext) -> ConstraintCheckResult

	// For printing out the results of the solution
	func result(in context: InferenceContext) -> String

	// Sorta bidirectional checking, a constraint that is known to expect
	// a certain type for a given property can have it specified here.
	var expectations: [PartialKeyPath<Self>: InferenceType] { get }
}

extension Constraint {
	var expectations: [PartialKeyPath<Self>: InferenceType] {
		[:]
	}
}
