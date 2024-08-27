//
//  CallConstraint.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/27/24.
//

import TalkTalkSyntax

struct CallConstraint: Constraint {
	let callee: InferenceResult
	let args: [InferenceResult]
	let returns: InferenceType
	let location: SourceLocation

	func solve(in context: InferenceContext) -> ConstraintCheckResult {
		let callee = context.applySubstitutions(
			to:	callee.asType(in: context)
		)

		switch callee {
		case .function(let params, let fnReturns):
			return solveFunction(params: params, fnReturns: fnReturns, in: context)
		case .structType:
			return .error([]) // TODO
		default:
			return .error([
				Diagnostic(message: "\(callee) not callable", severity: .error, location: location)
			])
		}
	}

	func solveFunction(params: [InferenceType], fnReturns: InferenceType, in context: InferenceContext) -> ConstraintCheckResult {
		if args.count != params.count {
			return .error([])
		}

		// Create a child context to evaluate args and params so we don't get leaks
		let childContext = context.childContext()

		for (arg, param) in zip(args, params) {
			childContext.unify(
				arg.asType(in: context),
				param
			)
		}

		if returns != fnReturns {
			childContext.unify(
				returns,
				fnReturns
			)
		}

		context.unify(returns, childContext.applySubstitutions(to: returns))

		return .ok
	}
}

extension Constraint where Self == CallConstraint {
	static func call(_ callee: InferenceResult, _ args: [InferenceResult], returns: InferenceType, at: SourceLocation) -> CallConstraint {
		CallConstraint(callee: callee, args: args, returns: returns, location: at)
	}
}
