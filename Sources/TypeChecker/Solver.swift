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
			print("-> \(constraint)")
			switch constraint.solve(in: context) {
			case .error(let diagnostics):
				print("!!!!!!!" + diagnostics.map(\.message).joined(separator: ", "))
			case .ok:
				print("<- \(constraint.result(in: context))")
			}
		}

		return context
	}
}
