//
//  InfixOperatorConstraint.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/25/24.
//

import TalkTalkSyntax

struct InfixOperatorConstraint: Constraint {
	let op: BinaryOperator
	let lhs: InferenceType
	let rhs: InferenceType
	let returns: TypeVariable
	let context: InferenceContext
	let location: SourceLocation

	func solve(in context: InferenceContext) -> ConstraintCheckResult {
		let lhs = self.context.applySubstitutions(to: lhs)
		let rhs = self.context.applySubstitutions(to: rhs)

		// Default rules for primitive types
		switch (lhs, rhs, op) {
		case (.base(.int), .base(.int), .plus),
		     (.base(.int), .base(.int), .minus),
		     (.base(.int), .base(.int), .star),
		     (.base(.int), .base(.int), .slash):
			return checkReturnType(.base(.int), returns: .base(.int), context: context)
		case (.base(.string), .base(.string), .plus):
			return checkReturnType(.base(.string), returns: .base(.string), context: context)
//		case (.base(.bool), .base(.bool), .and),
//		     (.base(.bool), .base(.bool), .or):
//			return checkReturnType(.base(.bool))
		default:
			context.unify(.typeVar(returns), .error(.constraintError("Infix operator \(op.rawValue) can't be used with operands \(lhs) and \(rhs)")))

			return .error([Diagnostic(
				message: "Invalid operator '\(op)' for types '\(lhs)' and '\(rhs)'",
				severity: .error,
				location: location
			)])
		}
	}

	private func checkReturnType(_ expectedType: InferenceType, returns: InferenceType, context: InferenceContext) -> ConstraintCheckResult {
		if returns == expectedType {
			context.unify(.typeVar(self.returns), returns)

			return .ok
		} else {
			return .error([Diagnostic(
				message: "Expected return type '\(expectedType)' but got '\(returns)'",
				severity: .error,
				location: location
			)])
		}
	}
}
