//
//  Unwrap.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 10/5/24.
//

import TalkTalkCore

extension Constraints {
	struct Unwrap: Constraint {
		let context: Context
		let value: InferenceResult
		let location: SourceLocation
		var retries: Int = 0

		var before: String {
			"Unwrap(value: \(value.debugDescription), location: \(location))"
		}

		var after: String {
			let value = context.applySubstitutions(to: value)
			return "Unwrap(value: \(value.debugDescription), location: \(location))"
		}

		func solve() throws {
			
		}
	}
}
