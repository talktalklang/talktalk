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
		let unwrapped: TypeVariable
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
			let type = context.applySubstitutions(to: value)

			switch type {
			case .instance(.enum(let instance)):
				let wrapped = instance.type.typeParameters["Wrapped"]!
				try context.bind(unwrapped, to: instance.substitutions[wrapped]!)
			default:
				if retries < 3 {
					context.retry(self)
				} else {
					context.error("Result not optional: \(value.debugDescription)", at: location)
				}
			}
		}
	}
}
