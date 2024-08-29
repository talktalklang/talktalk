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
			guard let instance = structType.instantiate(with: [:]).member(named: name, with: [:]) else {
				return .error(
					[Diagnostic(message: "No member \(name) for \(receiver)", severity: .error, location: location)]
				)
			}

			context.unify(
				context.applySubstitutions(to: instance),
				context.applySubstitutions(to: type.asType(in: context))
			)
		case .structInstance(let instance):
			// It's an instance member
			guard let member = instance.member(named: name, with: instance.substitutions) else {
				return .error(
					[Diagnostic(message: "No member \(name) for \(receiver)", severity: .error, location: location)]
				)
			}

//			// If the member type is generic, we need to swap it out for the instance's copy
//			if case let .typeVar(typeVar) = member, let instanceType = instance.substitutions[typeVar] {
//				member = instanceType
//			}

//			// Re-apply substitutions because each instance has their own copy of the struct context
//			let substitutedMember = instance.type.context.applySubstitutions(
//				to: member,
//				with: instance.substitutions
//			)

			context.unify(
				context.applySubstitutions(to: member),
				context.applySubstitutions(to: type.asType(in: context))
			)
		default:
			return .error([Diagnostic(message: "Receiver not a struct instance. Got: \(receiver)", severity: .error, location: location)])
		}

		return .ok
	}
}
