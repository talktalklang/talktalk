//
//  Solver.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/27/24.
//

struct Solver {
	let context: InferenceContext
	let constraints: Constraints
	var diagnostics: [Diagnostic] = []

	mutating func solve() -> InferenceContext {
		for constraint in constraints.constraints {
			print("-> Solving \(constraint)")
			constraint.solve(in: context)
		}

		return context
	}
}
