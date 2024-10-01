//
//  Constraints.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/25/24.
//

class Constraints {
	var constraints: [any InferenceConstraint] = []
	var deferredConstraints: [any InferenceConstraint] = []

	func add(_ constraint: any InferenceConstraint) {
		constraints.append(constraint)
	}

	func `defer`(_ constraint: any InferenceConstraint) {
		deferredConstraints.append(constraint)
	}

	func exists(forTypeVar typeVar: TypeVariable) -> Bool {
		for constraint in constraints {
			switch constraint {
			case let constraint as EqualityConstraint:
				if constraint.lhs == .type(.typeVar(typeVar)) || constraint.rhs == .type(.typeVar(typeVar)) {
					return true
				}
			case let constraint as InfixOperatorConstraint:
				if constraint.lhs == .typeVar(typeVar) || constraint.rhs == .typeVar(typeVar) {
					return true
				}
			default:
				continue
			}
		}

		return false
	}

	func exists<T: InferenceConstraint>(for _: T.Type, where block: (T) -> Bool) -> Bool {
		for constraint in constraints where constraint is T {
			if let constraint = constraint as? T, block(constraint) {
				return true
			}
		}

		return false
	}
}
