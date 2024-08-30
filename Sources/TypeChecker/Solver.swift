//
//  Solver.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/27/24.
//

struct Solver {
	let context: InferenceContext
	var diagnostics: [Diagnostic] = []

	mutating func solve() -> InferenceContext {
		while !context.constraints.constraints.isEmpty {
			let constraint = context.constraints.constraints.removeFirst()
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
