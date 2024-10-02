//
//  Call.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 10/1/24.
//

import TalkTalkCore

extension Constraints {
	struct Call: Constraint {
		let context: Context
		let callee: InferenceResult
		let args: [InferenceResult]
		let result: InferenceResult
		let location: SourceLocation
		var retries: Int = 0

		var before: String {
			"Call(callee: \(callee.debugDescription), args: \(args.debugDescription), result: \(result.debugDescription))"
		}

		var after: String {
			let callee = context.applySubstitutions(to: callee)
			let args = args.map { context.applySubstitutions(to: $0) }
			let result = context.applySubstitutions(to: result)

			return "Call(callee: \(callee.debugDescription), args: \(args.debugDescription), result: \(result.debugDescription))"
		}

		func solve() {
			let (_callee, freeVars) = callee.instantiate(in: context)
			let callee = context.applySubstitutions(to: .type(_callee))

			switch callee {
			case .function(let params, let returns):
				for (arg, param) in zip(args, params) {
					context.unify(freeVars[param] ?? param, arg, location)
				}

				context.unify(freeVars[returns] ?? returns, result, location)
			default:
				if retries > 1 {
					context.error("\(callee) not callable", at: location)
				} else {
					context.retry(self)
				}
			}
		}
	}
}
