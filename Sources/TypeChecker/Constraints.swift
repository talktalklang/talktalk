//
//  Constraints.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/25/24.
//

class Constraints {
	typealias ConstraintMap = [ConstraintType: [InferenceType: Constraint]]

	var map: ConstraintMap

	init(map: ConstraintMap = [:]) {
		self.map = map
		self.setupBuiltin()
	}

	func addConstraints(to inferenceType: InferenceType, _ constraints: [Constraint]) {
		for constraint in constraints {
			map[constraint.type, default: [:]][inferenceType] = constraint
		}
	}
}
