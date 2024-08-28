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
			if case let .error(diagnostics) = constraint.solve(in: context) {
				fatalError(diagnostics.map(\.message).joined(separator: ", "))
			}
		}

		return context
	}
}
