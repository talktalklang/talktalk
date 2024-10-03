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
		let expectedType: InferenceResult?
		let memberName: String
		let result: TypeVariable

		var retries: Int = 0
		var context: Context
		var location: SourceLocation

		func solve() throws {
			guard let receiver = (receiver ?? expectedType)?.instantiate(in: context) else {
				return
			}

			try solve(receiver: receiver.type, variables: receiver.variables)
		}

		func solve(receiver: InferenceType, variables: Substitutions, depth: Int = 0) throws {
			switch (receiver, variables) {
			case let (.type(type), variables):
				let member = type.staticMember(named: memberName)
				let instantiated = member?.instantiate(in: context, with: variables)

				if let instantiated {
					try context.unify(asInstance(instantiated, with: variables), .typeVar(result), location)
				}
			case let (.instance(wrapper), variables):
				let member = wrapper.type.member(named: memberName)
				let instantiated = member?.instantiate(in: context, with: wrapper.substitutions.merging(variables) { $1 })

				if let instantiated {
					try context.unify(asInstance(instantiated, with: variables), .typeVar(result), location)
				}
			case let (.self(type), variables):
				let member = type.member(named: memberName)
				let instantiated = member?.instantiate(in: context, with: variables)

				if let instantiated {
					try context.unify(asInstance(instantiated, with: variables), .typeVar(result), location)
				}
			case let (.typeVar(typeVar), variables):
				let receiver = context.applySubstitutions(to: .typeVar(typeVar), with: variables.asResults)

				if depth < 10 {
					try solve(receiver: receiver, variables: variables, depth: depth + 1)
				}

				if retries < 1 {
					context.retry(self)
				}

			default:
				try context.error("TODO Member.solve", at: location)
			}
		}

		var before: String {
			"Member(receiver: \(receiver?.debugDescription ?? ""), memberName: \(memberName))"
		}

		var after: String {
			let receiver = receiver.flatMap { context.applySubstitutions(to: $0) }
			return "Member(receiver: \(receiver?.debugDescription ?? ""), memberName: \(memberName))"
		}

		func asInstance(_ result: InstantiatedResult, with variables: [TypeVariable: InferenceType]) -> InferenceType {
			if case let .type(.struct(structType)) = result.type {
				let instance = structType.instantiate(with: result.variables.merging(variables) { $1 })
				return .instance(instance.wrapped)
			} else {
				return result.type
			}
		}
	}
}
