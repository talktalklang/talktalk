//
//  InfixOperatorConstraint.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/25/24.
//

import TalkTalkSyntax

struct InfixOperatorConstraint: Constraint {
	var type: ConstraintType
	let op: BinaryOperator
	var rhsTypes: [InferenceType]
	var returns: InferenceType

	func check(_ type: InferenceType, with args: [InferenceType]) -> ConstraintCheckResult {
		if rhsTypes.contains(args[0]) {
			return .ok(returns)
		} else {
			return .error(.constraintError("Infix operator + can't be used with \(type) + \(args[0])"))
		}
	}
}

extension Constraint where Self == InfixOperatorConstraint {
	static func infixOperator(_ op: BinaryOperator, rhs: [InferenceType], returns: InferenceType) -> InfixOperatorConstraint {
		InfixOperatorConstraint(type: .infixOperator(op), op: op, rhsTypes: rhs, returns: returns)
	}
}
