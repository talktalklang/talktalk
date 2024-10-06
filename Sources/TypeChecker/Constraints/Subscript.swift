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

		func solve() throws {
			let receiver = context.applySubstitutions(to: receiver)

			guard case let .instance(receiver) = receiver else {
				context.error("No `get` method found for subscript receiver \(receiver.debugDescription)", at: location)
				return
			}

			guard let getMethod = receiver.member(named: "get"),
			      case let .function(_, returns) = getMethod.instantiate(in: context, with: receiver.substitutions).type
			else {
				context.error("No `get` method found for subscript receiver \(receiver.debugDescription)", at: location)
				return
			}

			let returnsType = returns.instantiate(in: context, with: receiver.substitutions).type

			if case .typeVar = returnsType, retries < 2 {
				context.retry(self)
				return
			}

			try context.unify(returnsType, .typeVar(result), location)
		}
	}
}
