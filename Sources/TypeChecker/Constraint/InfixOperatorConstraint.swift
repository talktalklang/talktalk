//
//  InfixOperatorConstraint.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/25/24.
//

import TalkTalkCore

struct InfixOperatorConstraint: InferenceConstraint {
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

		return "InfixOperatorConstraint(lhs: \(lhs.debugDescription), rhs: \(rhs.debugDescription), op: \(op.rawValue), returns: \(returns.debugDescription))"
	}

	var description: String {
		"InfixOperatorConstraint(lhs: \(lhs.debugDescription), rhs: \(rhs.debugDescription), op: \(op.rawValue), returns: \(returns.debugDescription))"
	}

	func solve(in context: InferenceContext) -> ConstraintCheckResult {
		let lhs = self.context.applySubstitutions(to: lhs)
		let rhs = self.context.applySubstitutions(to: rhs)

		// Default rules for primitive types
		switch (lhs, rhs, op) {
		case (.base(.pointer), .base(.int), .plus),
		     (.base(.pointer), .base(.int), .minus):

			context.unify(.typeVar(returns), .base(.pointer), location)

			return .ok
		case let (.base(.int), type, .plus),
		     let (.base(.int), type, .minus),
		     let (.base(.int), type, .star),
		     let (.base(.int), type, .slash),
		     let (type, .base(.int), .plus),
		     let (type, .base(.int), .minus),
		     let (type, .base(.int), .star),
		     let (type, .base(.int), .slash):

			context.unify(type, .base(.int), location)

			return checkReturnType(type, expect: .base(.int), context: context)
		case let (.base(.string), type, .plus),
		     let (type, .base(.string), .plus):
			context.unify(type, .base(.string), location)

			return checkReturnType(type, expect: .base(.string), context: context)
		case let (lhs, rhs, .equalEqual):
			context.unify(.typeVar(returns), .base(.bool), location)
			context.unify(lhs, rhs, location)
			return .ok
		default:
			context.unify(lhs, .typeVar(returns), location)
			context.unify(rhs, .typeVar(returns), location)

			context.addConstraint(
				.equality(lhs, .typeVar(returns), at: location)
			)
			context.addConstraint(
				.equality(rhs, .typeVar(returns), at: location)
			)

			return .ok
		}
	}

	private func checkReturnType(_ type: InferenceType, expect: InferenceType, context: InferenceContext) -> ConstraintCheckResult {
		if context.applySubstitutions(to: type) == expect {
			context.unify(.typeVar(returns), type, location)

			return .ok
		} else {
			context.unify(
				.typeVar(returns),
				.error(
					.init(
						kind: .constraintError("Infix operator \(op.rawValue) can't be used with operands \(lhs) and \(rhs)"),
						location: location
					)
				),
				location
			)

			return .error([Diagnostic(
				message: "Invalid operator '\(op)' for types '\(lhs)' and '\(rhs)'",
				severity: .error,
				location: location
			)])
		}
	}
}
