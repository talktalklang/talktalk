//
//  Infix.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 10/1/24.
//

import TalkTalkCore

extension Constraints {
	struct Infix: Constraint {
		let context: Context
		let lhs: InferenceResult
		let rhs: InferenceResult
		let op: BinaryOperator
		let result: TypeVariable
		let location: SourceLocation
		var retries: Int = 0

		var before: String {
			"Infix(lhs: \(lhs.debugDescription), rhs: \(rhs.debugDescription), op: \(op), result: \(result.debugDescription))"
		}

		var after: String {
			let lhs = context.applySubstitutions(to: lhs)
			let rhs = context.applySubstitutions(to: rhs)
			let result = context.applySubstitutions(to: .resolved(.typeVar(result)))

			return "Infix(lhs: \(lhs.debugDescription), rhs: \(rhs.debugDescription), op: \(op), result: \(result.debugDescription))"
		}

		func solve() throws {
			let lhs = context.applySubstitutions(to: lhs)
			let rhs = context.applySubstitutions(to: rhs)

			// Default rules for primitive types
			switch (lhs, rhs, op) {
			case (.base(.pointer), .base(.int), .plus),
				(.base(.pointer), .base(.int), .minus):

				try context.unify(.typeVar(result), .base(.pointer), location)
			case (.base(.int), .base(.int), _):
				try context.unify(.typeVar(result), .base(.int), location)
			case let (.base(.int), .typeVar(variable), .plus),
				let (.base(.int), .typeVar(variable), .minus),
				let (.base(.int), .typeVar(variable), .star),
				let (.base(.int), .typeVar(variable), .slash),
				let (.base(.int), .typeVar(variable), .less),
				let (.base(.int), .typeVar(variable), .lessEqual),
				let (.base(.int), .typeVar(variable), .greater),
				let (.base(.int), .typeVar(variable), .greaterEqual),
				let (.typeVar(variable), .base(.int), .plus),
				let (.typeVar(variable), .base(.int), .minus),
				let (.typeVar(variable), .base(.int), .star),
				let (.typeVar(variable), .base(.int), .slash),
				let (.typeVar(variable), .base(.int), .less),
				let (.typeVar(variable), .base(.int), .lessEqual),
				let (.typeVar(variable), .base(.int), .greater),
				let (.typeVar(variable), .base(.int), .greaterEqual):

				try context.unify(.typeVar(variable), .base(.int), location)
				try context.unify(.typeVar(result), .base(.int), location)
			case (.base(.string), (.base(.string)), .plus):
				try context.unify(.typeVar(result), .base(.string), location)
			case let (.typeVar(lhs), .typeVar(rhs), _):
				// Just say that it's the same as the result and hope for the best
				try context.unify(.typeVar(lhs), .typeVar(result), location)
				try context.unify(.typeVar(rhs), .typeVar(result), location)
			case let (.typeVar(typeVar), type, .equalEqual), let (type, .typeVar(typeVar), .equalEqual),
					let (.typeVar(typeVar), type, .bangEqual), let (type, .typeVar(typeVar), .bangEqual):
				try context.unify(.typeVar(typeVar), type, location)
			case let (.self(lhs), .instance(rhs), .equalEqual), let (.instance(rhs), .self(lhs), .equalEqual),
				let (.self(lhs), .instance(rhs), .bangEqual), let (.instance(rhs), .self(lhs), .bangEqual):
				try context.unify(.type(lhs.wrapped), .type(rhs.type.wrapped), location)
				try context.unify(.typeVar(result), .base(.bool), location)
			case (.base(.none), _, .equalEqual), (_, .base(.none), .equalEqual),
					 (.base(.none), _, .bangEqual), (_, .base(.none), .bangEqual):
				try context.unify(.base(.bool), .typeVar(result), location)
			default:
				if retries < 2 {
					context.retry(self)
				} else {
//					context.error("Infix operator \(op.rawValue) can't be used with operands \(lhs.debugDescription) and \(rhs.debugDescription)", at: location)
					try context.unify(lhs, rhs, location)
				}
			}
		}
	}
}
