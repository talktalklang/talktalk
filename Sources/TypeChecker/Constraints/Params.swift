//
//  Params.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 10/4/24.
//

import TalkTalkCore

extension Constraints {
	struct Params: Constraint {
		let context: Context
		let callee: InferenceResult
		let args: [Pattern]
		let location: SourceLocation
		var retries: Int = 0

		var before: String {
			""
		}

		var after: String {
			""
		}

		func solve() throws {
			print()
		}

		func parameters(for type: InferenceResult, in context: Context, location: SourceLocation) -> [InferenceResult] {
			switch type {
			case let .scheme(scheme):
				return parameters(for: .resolved(scheme.type), in: context, location: location)
			case let .resolved(.function(params, _)):
				return params
			case let .resolved(.type(.enumCase(kase))):
				return kase.attachedTypes
			default:
				context.error("Could not determine parameters for \(type)", at: location)
				return []
			}
		}
	}
}
