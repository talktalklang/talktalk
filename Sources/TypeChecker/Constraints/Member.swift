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
			try solve(receiver: receiver, depth: 0)
		}

		func resolveReceiver(receiver: InferenceResult?) throws -> InstantiatedResult? {
			var resolvedReceiver: InstantiatedResult? = nil

			if let receiver {
				resolvedReceiver = receiver.instantiate(in: context)
			}

			if let expectedType {
				let result = expectedType.instantiate(in: context.parent ?? context)
				resolvedReceiver = .init(
					type: context.applySubstitutions(to: result.type, with: result.variables.asResults),
					variables: result.variables
				)
			}

			// If we don't have a resolved receiver still, see if we can use a static member
			if resolvedReceiver == nil, let lexicalScope = context.lookupLexicalScope() {
				resolvedReceiver = .init(type: .type(lexicalScope.wrapped), variables: [:])
			}

			return resolvedReceiver
		}

		func solve(receiver: InferenceResult?, depth: Int = 0) throws {
			let resolvedReceiver = try resolveReceiver(receiver: receiver)

			guard let resolvedReceiver else {
				if retries > 1 {
					context.error("Could not resolve receiver of member \(memberName)", at: location)
				} else {
					context.retry(self)
				}

				return
			}

			switch (resolvedReceiver.type, resolvedReceiver.variables) {
			case let (.type(type), variables):
				let member = type.staticMember(named: memberName)
				let instantiated = member?.instantiate(in: context, with: variables)

				if let instantiated {
					try context.unify(asInstance(instantiated, with: variables), .typeVar(result), location)
				}
			case let (.instance(wrapper), variables):
				if let member = wrapper.type.member(named: memberName) {
					let instantiated = member.instantiate(in: context, with: wrapper.substitutions.merging(variables) { $1 })
					try context.unify(asInstance(instantiated, with: variables), .typeVar(result), location)
				} else {
					try context.unify(.instance(wrapper), .typeVar(result), location)
				}
			case let (.self(type), variables):
				let member = type.member(named: memberName)
				let instantiated = member?.instantiate(in: context, with: variables)

				if let instantiated {
					try context.unify(asInstance(instantiated, with: variables), .typeVar(result), location)
				}
			case let (.typeVar(typeVar), variables):
				let receiver = context.applySubstitutions(to: .typeVar(typeVar), with: variables.asResults)

				if depth < 1 {
					try solve(receiver: .resolved(receiver), depth: depth + 1)
				}

				if retries < 1 {
					context.retry(self)
				}
			case (.placeholder, _):
				if retries < 1 {
					context.retry(self)
				}
			default:
				print("TODO: Member.solve: \(receiver)")
				context.error("TODO Member.solve", at: location)
			}
		}

		var before: String {
			"Member(receiver: \(receiver?.debugDescription ?? ""), memberName: \(memberName), expectedType: \(expectedType?.debugDescription ?? "nil"))"
		}

		var after: String {
			let receiver = receiver.flatMap { context.applySubstitutions(to: $0) }
			let expectedType = expectedType.flatMap { context.applySubstitutions(to: $0) }

			return "Member(receiver: \(receiver?.debugDescription ?? ""), memberName: \(memberName), expectedType: \(expectedType?.debugDescription ?? "nil"))"
		}

		func asInstance(_ result: InstantiatedResult, with variables: [TypeVariable: InferenceType]) -> InferenceType {
			if case let .type(type) = result.type {
				let instance = type.instantiate(with: result.variables.merging(variables) { $1 })
				return .instance(instance)
			} else {
				return result.type
			}
		}
	}
}
