//
//  ParamsConstraint.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/29/24.
//


import TalkTalkCore

// When we have args and a callee we don't know, we can unify here
struct ParamsConstraint: Constraint {
	let callee: InferenceResult
	let args: [InferenceResult]
	let location: SourceLocation
	let isRetry: Bool

	func result(in context: InferenceContext) -> String {
		let callee = context.applySubstitutions(to: callee)
		let args = args.map { context.applySubstitutions(to: $0) }
		return "ParamsConstraint(callee: \(callee.debugDescription), value: \(args.debugDescription))"
	}

	var description: String {
		"ParamsConstraint(callee: \(callee.debugDescription), value: \(args.debugDescription))"
	}

	func solve(in context: InferenceContext) -> ConstraintCheckResult {
		let callee = context.applySubstitutions(to: callee)

		switch callee {
		case .enumCase(let enumCase):
			for (param, arg) in zip(enumCase.attachedTypes, args) {
				context.unify(param, arg.asType(in: context), location)
			}
		case .function(let params, _):
			for (param, arg) in zip(params, args) {
				context.unify(param.asType(in: context), arg.asType(in: context), location)
			}
		case .base: 
			context.unify(callee, args[0].asType(in: context), location)
		default:
			if isRetry {
				return .error([.init(message: "Could not determine params for \(callee)", severity: .error, location: location)])
			} else {
				context.deferConstraint(ParamsConstraint(callee: self.callee, args: args, location: location, isRetry: true))
			}
		}

		return .ok
	}
}
