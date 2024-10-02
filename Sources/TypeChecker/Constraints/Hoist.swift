//
//  Hoist.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 10/1/24.
//

import TalkTalkCore

extension Constraints {
	// The Hoist constraint lets a context pull types from child contexts
	struct Hoist: Constraint {
		let context: Context
		let parent: Context
		let variables: [TypeVariable]
		let location: SourceLocation
		var retries: Int = 0

		var before: String {
			"Hoist(variables: \(variables.debugDescription))"
		}

		var after: String {
			"Hoist(variables: \(variables.map { context.applySubstitutions(to: .type(.typeVar($0))).debugDescription })"
		}

		func solve() {
			for typeVariable in variables {
				context.log("Hoisting \(typeVariable.debugDescription) -> \(context.applySubstitutions(to: .type(.typeVar(typeVariable))))", prefix: " ^ ")
				parent.substitutions[typeVariable] = context.substitutions[typeVariable]
			}
		}
	}
}
