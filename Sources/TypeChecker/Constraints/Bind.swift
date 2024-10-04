//
//  Bind.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 10/3/24.
//

import TalkTalkCore

extension Constraints {
	// The Equality constraint just makes sure two types are the same
	struct Bind: Constraint {
		let context: Context
		let target: InferenceResult
		let pattern: Pattern
		let location: SourceLocation
		var retries: Int = 0

		var before: String {
			"Bind(target: \(target.debugDescription), pattern: \(pattern.debugDescription), location: \(location))"
		}

		var after: String {
			let target = context.applySubstitutions(to: target)
			let pattern = context.applySubstitutions(to: .type(.pattern(pattern)))
			return "Bind(target: \(target.debugDescription), pattern: \(pattern.debugDescription), location: \(location))"
		}

		func solve() throws {
			try solve(result: target, pattern: pattern)
		}

		private func solve(result: InferenceResult, pattern: Pattern) throws {
			switch context.applySubstitutions(to: result) {
			case .instance(.enumCase(let instance)):
				try solveEnumCase(instance, pattern: pattern)
			case .base(let type):
				try solveBase(type, pattern: pattern)
			default:
				if retries < 10 {
					context.retry(self)
				} else {
					context.error("Could not resolve pattern binding", at: location)
				}
			}
		}

		private func solveBase(_ type: Primitive, pattern: Pattern) throws {
			switch pattern {
			case .variable(_, let result):
				try context.unify(.base(type), result.instantiate(in: context).type, location)
			case .call(_, _):
				()
			}
		}

		private func solveEnumCase(_ instance: Instance<Enum.Case>, pattern: Pattern) throws {
			switch pattern {
			case .variable(let string, let inferenceResult):
				print()
				()
			case .call(_, let args):
				for (param, pattern) in zip(instance.type.attachedTypes, args) {
					let param = context.applySubstitutions(to: param, with: instance.substitutions.asResults)

					try solve(result: .type(param), pattern: pattern)
				}
			}
		}
	}
}
