//
//  Equality.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 10/2/24.
//

import TalkTalkCore

extension Constraints {
	// The Equality constraint just makes sure two types are the same
	struct Equality: Constraint {
		let context: Context
		let lhs: InferenceResult
		let rhs: InferenceResult
		let location: SourceLocation
		var retries: Int = 0

		var before: String {
			"Equality(lhs: \(lhs.debugDescription), rhs: \(rhs.debugDescription), location: \(location))"
		}

		var after: String {
			let lhs = context.applySubstitutions(to: lhs)
			let rhs = context.applySubstitutions(to: rhs)
			return "Equality(lhs: \(lhs.debugDescription), rhs: \(rhs.debugDescription), location: \(location))"
		}

		func solve() throws {
			try context.unify(
				lhs.instantiate(in: context).type,
				rhs.instantiate(in: context).type,
				location
			)
		}
	}
}
