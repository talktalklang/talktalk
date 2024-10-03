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

		func solve() throws {
			guard let receiver = receiver?.instantiate(in: context) else {
				return
			}

			switch (receiver.type, receiver.variables) {
			case let (.struct(type), variables):
				let member = type.staticMember(named: memberName)
				let instantiated = member?.instantiate(in: context, with: variables)

				if let instantiated {
					try context.unify(asInstance(instantiated, with: variables), .type(.typeVar(result)), location)
				}
			case let (.instance(wrapper), variables):
				let member = wrapper.type.member(named: memberName)
				let instantiated = member?.instantiate(in: context, with: wrapper.substitutions.merging(variables) { $1 })

				if let instantiated {
					try context.unify(asInstance(instantiated, with: variables), .type(.typeVar(result)), location)
				}
			case let (.self(type), variables):
				let member = type.member(named: memberName)
				let instantiated = member?.instantiate(in: context, with: variables)

				if let instantiated {
					try context.unify(asInstance(instantiated, with: variables), .type(.typeVar(result)), location)
				}
			case let (.typeVar(typeVar), variables):
				let receiver = context.applySubstitutions(to: .type(.typeVar(typeVar)), with: variables)

				let variables = if case let .instance(wrapper) = receiver {
					wrapper.substitutions.merging(variables) { $1 }
				} else {
					variables
				}

				if let memberResult = receiver.member(named: memberName)?.instantiate(in: context, with: variables) {
					try context.unify(.type(.typeVar(result)), asInstance(memberResult, with: variables), location)
				} else {
					print()
				}
			default:
				try context.error("TODO", at: location)
			}
		}
		
		var before: String {
			"Member(receiver: \(receiver?.description ?? ""), memberName: \(memberName))"
		}

		var after: String {
			"Member(receiver: \(receiver?.description ?? ""), memberName: \(memberName))"
		}

		func asInstance(_ result: InstantiatedResult, with variables: [TypeVariable: InferenceResult]) -> InferenceResult {
			if case let .struct(structType) = result.type {
				let instance = structType.instantiate(with: result.variables.merging(variables) { $1 })
				return .type(.instance(instance.wrapped))
			} else {
				return .type(result.type)
			}
		}
	}
}
