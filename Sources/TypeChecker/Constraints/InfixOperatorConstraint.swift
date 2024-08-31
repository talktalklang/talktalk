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

	func result(in context: InferenceContext) -> String {
		let lhs = context.applySubstitutions(to: lhs)
		let rhs = context.applySubstitutions(to: rhs)
		let returns = context.applySubstitutions(to: .typeVar(returns))

		return "InfixOperatorConstraint(lhs: \(lhs), rhs: \(rhs), op: \(op.rawValue), returns: \(returns))"
	}

	var description: String {
		"EqualityConstraint(lhs: \(lhs), rhs: \(rhs))"
	}

	func solve(in context: InferenceContext) -> ConstraintCheckResult {
		let lhs = self.context.applySubstitutions(to: lhs)
		let rhs = self.context.applySubstitutions(to: rhs)

		// Default rules for primitive types
		switch (lhs, rhs, op) {
		case (.base(.int), let type, .plus),
		     (.base(.int), let type, .minus),
		     (.base(.int), let type, .star),
		     (.base(.int), let type, .slash),
				 (let type, .base(.int), .plus),
				 (let type, .base(.int), .minus),
				 (let type, .base(.int), .star),
				 (let type, .base(.int), .slash):

			context.unify(type, .base(.int))

			return checkReturnType(type, expect: .base(.int), context: context)
		case (.base(.string), let type, .plus),
				 (let type, .base(.string), .plus):
			context.unify(type, .base(.string))

			return checkReturnType(type, expect: .base(.string), context: context)
//		case (.base(.bool), .base(.bool), .andAnd),
//		     (.base(.bool), .base(.bool), .pipePipe):
//			return checkReturnType(.base(.bool))
		default:
			return .error([Diagnostic(
				message: "Invalid operator '\(op)' for types '\(lhs)' and '\(rhs)'",
				severity: .error,
				location: location
			)])
		}
	}

	private func checkReturnType(_ type: InferenceType, expect: InferenceType, context: InferenceContext) -> ConstraintCheckResult {
		if context.applySubstitutions(to: type) == expect {
			context.unify(.typeVar(self.returns), type)

			return .ok
		} else {
			context.unify(.typeVar(returns), .error(.constraintError("Infix operator \(op.rawValue) can't be used with operands \(lhs) and \(rhs)")))

			return .error([Diagnostic(
				message: "Invalid operator '\(op)' for types '\(lhs)' and '\(rhs)'",
				severity: .error,
				location: location
			)])
		}
	}
}
