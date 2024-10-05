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
			let pattern = context.applySubstitutions(to: .resolved(.pattern(pattern)))
			return "Bind(target: \(target.debugDescription), pattern: \(pattern.debugDescription), location: \(location))"
		}

		func solve() throws {
			try solve(result: target, pattern: pattern)
		}

		private func solve(result: InferenceResult, pattern: Pattern) throws {
			let result = context.applySubstitutions(to: result)
			let pattern = context.applySubstitutions(to: pattern, with: [:])

			switch result {
			case .instance(.enumCase(let instance)):
				try solveEnumCase(instance, pattern: pattern)
			case .instance(let instance):
				try solveInstance(instance, pattern: pattern)
			case .type(.enumCase(let kase)):
				try solveEnumCase(kase, pattern: pattern)
			case .base(let type):
				try solveBase(type, pattern: pattern)
			case .type(let type):
				try solveType(type, pattern: pattern)
			default:
				if retries < 3 {
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
			case .value(let value):
				try context.unify(value, .base(type), location)
			case .call(_, _):
				()
			}
		}

		private func solveEnumCase(_ instance: Instance<Enum.Case>, pattern: Pattern) throws {
			switch pattern {
			case .variable(_, _):
				print()
			case .value(let value):
				try context.unify(value, .pattern(pattern), location)
			case .call(_, let args):
				for (param, pattern) in zip(instance.type.attachedTypes, args) {
					let param = context.applySubstitutions(to: param, with: instance.substitutions.asResults)

					try solve(result: .resolved(param), pattern: pattern)
				}
			}
		}

		private func solveEnumCase(_ kase: Enum.Case, pattern: Pattern) throws {
			switch pattern {
			case .variable(_, _):
				print()
			case .value(_):
				print()
			case .call(_, let args):
				for (param, pattern) in zip(kase.attachedTypes, args) {
					let param = context.applySubstitutions(to: param)

					try solve(result: .resolved(param), pattern: pattern)
				}
			}
		}

		private func solveInstance(_ instance: InstanceWrapper, pattern: Pattern) throws {
			let substitutions = instance.substitutions

			switch pattern {
			case .variable(_, _):
				print()
			case .value(let value):
				try context.unify(value, .pattern(pattern), location)
			case .call(.resolved(.type(.enumCase(let kase))), _):
				let instance = kase.instantiate(with: instance.substitutions)
				try solveEnumCase(instance, pattern: pattern)
			default:
				print()
			}
		}

		private func solveType(_ type: TypeWrapper, pattern: Pattern) throws {
			switch pattern {
			case let .call(.resolved(.instance(.enumCase(kase))), _):
				try solveEnumCase(kase, pattern: pattern)
			case let .call(.resolved(.type(.enumCase(kase))), _):
				try solveEnumCase(kase, pattern: pattern)
			default:
				try context.unify(.type(type), .pattern(pattern), location)
			}
		}
	}
}
