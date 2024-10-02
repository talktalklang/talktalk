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
			guard let receiver = receiver?.instantiate(in: context) else {
				return
			}

			switch (receiver.type, receiver.variables) {
			case let (.struct(type), variables):
				let member = type.staticMember(named: memberName)
				let instantiated = member?.instantiate(in: context, with: variables)

				if let instantiated {
					context.unify(asInstance(instantiated), .type(.typeVar(result)), location)
				}
			case let (.self(type), variables):
				let member = type.member(named: memberName)
				let instantiated = member?.instantiate(in: context, with: variables)

				if let instantiated {
					context.unify(asInstance(instantiated), .type(.typeVar(result)), location)
				}
			case let (.typeVar(typeVar), _):
				let type = context.applySubstitutions(to: .type(.typeVar(typeVar)))

				if let memberResult = type.member(named: memberName)?.instantiate(in: context, with: receiver.variables) {
					context.unify(asInstance(memberResult), .type(.typeVar(result)), location)
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

		func asInstance(_ result: InstantiatedResult) -> InferenceResult {
			if case let .struct(structType) = result.type {
				let instance = structType.instantiate(with: result.variables)
				return .type(.instance(instance.wrapped))
			} else {
				return .type(result.type)
			}
		}
	}
}
