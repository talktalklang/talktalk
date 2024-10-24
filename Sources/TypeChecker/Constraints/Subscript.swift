//
//  Subscript.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 10/5/24.
//

import TalkTalkCore

extension Constraints {
	struct Subscript: Constraint {
		let context: Context
		let receiver: InferenceResult
		let args: [InferenceResult]
		let result: TypeVariable
		let location: SourceLocation
		var retries: Int = 0

		var before: String {
			"Subscript(receiver: \(receiver.debugDescription), args: \(args.debugDescription), location: \(location))"
		}

		var after: String {
			let receiver = context.applySubstitutions(to: receiver)
			let args = args.map { context.applySubstitutions(to: $0) }
			return "Subscript(receiver: \(receiver.debugDescription), args: \(args.debugDescription), location: \(location))"
		}

		func getMethod(from type: InferenceType) -> InstantiatedResult? {
			switch type {
			case let .instance(instance):
				return instance.member(named: "get")?.instantiate(in: context, with: instance.substitutions)
			case let .self(type):
				return type.member(named: "get")?.instantiate(in: context)
			default:
				return nil
			}
		}

		func solve() throws {
			let receiver = context.applySubstitutions(to: receiver).asInstance(with: [:])


			guard let getMethod = getMethod(from: receiver),
						case let .function(_, returns) = getMethod.type	else {
				if retries < 1 {
					context.retry(self)
				} else {
					context.error("No `get` method found for subscript receiver \(receiver.debugDescription)", at: location)
				}
				return
			}

			let returnsType = returns.instantiate(in: context, with: getMethod.variables).type

			if case .typeVar = returnsType, retries < 2 {
				context.retry(self)
				return
			}

			try context.unify(returnsType, .typeVar(result), location)
		}
	}
}
