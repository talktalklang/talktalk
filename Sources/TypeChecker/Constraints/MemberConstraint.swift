//
//  MemberConstraint.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/27/24.
//

import TalkTalkSyntax

struct MemberConstraint: Constraint {
	let receiver: InferenceType
	let name: String
	let type: InferenceType

	var location: SourceLocation
	
	func solve(in context: InferenceContext) -> ConstraintCheckResult {
		switch context.applySubstitutions(to: receiver) {
		case .structInstance(let structType):
			if let member = structType.memberForInstance(named: name)?.asType(in: context) {
				context.unify(
					context.applySubstitutions(to: member),
					context.applySubstitutions(to: type)
				)
			} else {
				return .error([Diagnostic(message: "No member \(name) for \(receiver)", severity: .error, location: location)])
			}
		default:
			return .error([Diagnostic(message: "Receiver not a struct instance. Got: \(receiver)", severity: .error, location: location)])
		}

		return .ok
	}
}
