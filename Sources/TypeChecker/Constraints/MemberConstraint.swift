//
//  MemberConstraint.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/27/24.
//

import TalkTalkSyntax

struct MemberConstraint: Constraint {
	let receiver: InferenceResult
	let name: String
	let type: InferenceResult

	func result(in context: InferenceContext) -> String {
		let receiver = context.applySubstitutions(to: receiver.asType(in: context))
		let type = context.applySubstitutions(to: type.asType(in: context))

		return "MemberConstraint(receiver: \(receiver), name: \(name), type: \(type))"
	}

	var description: String {
		"MemberConstraint(receiver: \(receiver), name: \(name), type: \(type))"
	}

	var location: SourceLocation

	func solve(in context: InferenceContext) -> ConstraintCheckResult {
		switch context.applySubstitutions(to: receiver.asType(in: context)) {
		case .structType(let structType):
			// It's a type parameter, try to unify it with a property
			for (_, propertyType) in structType.properties {
				switch propertyType.asType(in: context) {
				case .typeVar(let propertyType):
					if case .type(let inferenceType) = type {
						structType.context.unify(.typeVar(propertyType), inferenceType)
					}
				default:
					continue
				}
			}

		case .structInstance(let structType):
			// It's an instance member
			guard let member = structType.memberForInstance(named: name)?.asType(in: context) else {
				return .error(
					[Diagnostic(message: "No member \(name) for \(receiver)", severity: .error, location: location)]
				)
			}

			// Re-apply substitutions because each instance has their own copy of the struct context
			let substitutedMember = structType.context.applySubstitutions(to: member)

			context.unify(
				context.applySubstitutions(to: substitutedMember),
				context.applySubstitutions(to: type.asType(in: context))
			)
		default:
			return .ok // .error([Diagnostic(message: "Receiver not a struct instance. Got: \(receiver)", severity: .error, location: location)])
		}

		return .ok
	}
}
