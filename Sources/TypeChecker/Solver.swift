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
			context.log(constraint.description, prefix: "-> ")
			switch constraint.solve(in: context) {
			case .error(let diagnostics):
				print("!!!!!!!" + diagnostics.map(\.message).joined(separator: ", "))
			case .ok:
				context.log(constraint.result(in: context), prefix: "<- ")
			}
		}

		return context
	}
}
