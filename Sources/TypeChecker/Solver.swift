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
			case let .error(diagnostics):
				context.log(diagnostics.map(\.message).joined(separator: ", "), prefix: " ! ")
				self.diagnostics.append(contentsOf: diagnostics)
			case .ok:
				context.log(constraint.result(in: context), prefix: "<- ")
			}
		}

		for diagnostic in diagnostics where diagnostic.severity == .error {
			context.addError(.init(kind: .diagnosticError(diagnostic), location: diagnostic.location))
		}

		return context
	}

	mutating func solveDeferred() -> InferenceContext {
		while !context.constraints.deferredConstraints.isEmpty {
			let constraint = context.constraints.deferredConstraints.removeFirst()
			context.log(constraint.description, prefix: "-> ")
			switch constraint.solve(in: context) {
			case let .error(diagnostics):
				context.log(diagnostics.map(\.message).joined(separator: ", "), prefix: " ! ")
			case .ok:
				context.log(constraint.result(in: context), prefix: "<- ")
			}
		}

		for diagnostic in diagnostics where diagnostic.severity == .error {
			context.addError(.init(kind: .diagnosticError(diagnostic), location: diagnostic.location))
		}

		return context
	}
}
