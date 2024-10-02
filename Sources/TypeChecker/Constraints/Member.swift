//
//  Member.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 10/2/24.
//

import TalkTalkCore

extension Constraints {
	struct Member: Constraint {
		let receiver: InferenceResult?
		let memberName: String
		let result: TypeVariable

		var retries: Int = 0
		var context: Context
		var location: SourceLocation

		func solve() {
			guard let instantiatedReceiver = receiver?.instantiate(in: context) else {
				return
			}

			switch instantiatedReceiver {
			case let (.self(type), freeVariables):
				let member = type.member(named: memberName)
				let instantiated = member?.instantiate(in: context, with: freeVariables)

				if let instantiated {
					context.unify(.type(instantiated.0), .type(.typeVar(result)), location)
				}
			case let (.typeVar(typeVar), _):
				let type = context.applySubstitutions(to: .type(.typeVar(typeVar)))
				if let memberResult = type.member(named: memberName) {
					context.unify(memberResult, .type(.typeVar(result)), location)
				} else {
					print()
				}
			default:
				context.error("TODO", at: location)
			}
		}
		
		var before: String {
			"Member(receiver: \(receiver?.description ?? ""), memberName: \(memberName))"
		}

		var after: String {
			"Member(receiver: \(receiver?.description ?? ""), memberName: \(memberName))"
		}
	}
}
