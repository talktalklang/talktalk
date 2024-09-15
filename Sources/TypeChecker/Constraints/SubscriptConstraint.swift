//
//  SubscriptConstraint.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/31/24.
//

import TalkTalkSyntax

struct SubscriptConstraint: Constraint {
	let receiver: InferenceResult
	let args: [InferenceResult]
	let returns: InferenceType
	let location: SourceLocation
	let isRetry: Bool

	var description: String {
		"SubscriptConstraint(receiver: \(receiver), args: \(args.map(\.description).joined(separator: ", ")), returns: \(returns))"
	}

	func solve(in context: InferenceContext) -> ConstraintCheckResult {
		let receiver = context.applySubstitutions(to: receiver)
		switch receiver {
		case let .structInstance(instance):
			guard let getMethod = instance.type.method(named: "get") else {
				return .error([
					Diagnostic(message: "\(instance.type.name) has no get method", severity: .error, location: location),
				])
			}

			switch context.applySubstitutions(to: getMethod, with: instance.substitutions) {
			case let .function(params, fnReturns):
				// TODO: Validate params/args count
				for (arg, param) in zip(args, params) {
					context.unify(arg.asType(in: context), param, location)
				}

				if case let .structType(structType) = fnReturns {
					context.unify(
						returns,
						.structInstance(structType.instantiate(with: instance.substitutions, in: context)),
						location
					)
				} else {
					context.unify(returns, fnReturns, location)
				}

			default:
				()
			}
		default:
			()
		}

		return .ok
	}

	func result(in context: InferenceContext) -> String {
		let receiver = context.applySubstitutions(to: receiver.asType(in: context))
		let args = args.map { context.applySubstitutions(to: $0.asType(in: context)) }
		let returns = context.applySubstitutions(to: returns)

		return "SubscriptConstraint(receiver: \(receiver), args: \(args.map(\.description).joined(separator: ", ")), returns: \(returns))"
	}
}
