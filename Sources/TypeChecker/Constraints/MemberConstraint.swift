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
		let receiver =
			receiver.asType(in: context)

		let type = context.applySubstitutions(to: type.asType(in: context))

		return "MemberConstraint(receiver: \(receiver), name: \(name), type: \(type))"
	}

	func resolveReceiver(_ receiver: InferenceResult?) -> InferenceResult {
		if let receiver {
			return receiver
		}

		return .type(.any)
	}

	var description: String {
		"MemberConstraint(receiver: \(receiver.description), name: \(name), type: \(type))"
	}

	var location: SourceLocation

	func solve(in context: InferenceContext) -> ConstraintCheckResult {
		let receiver = context.applySubstitutions(to: resolveReceiver(receiver).asType(in: context))
		return resolve(
			withReceiver: receiver,
			name: self.name,
			type: self.type.asType(in: context),
			in: context
		)
	}

	func resolve(withReceiver receiver: InferenceType, name: String, type: InferenceType, in context: InferenceContext) -> ConstraintCheckResult {
		let resolvedType = context.applySubstitutions(to: type)

		switch context.applySubstitutions(to: receiver) {
		case .structType(let structType):
			// It's a type parameter, try to unify it with a property
			guard let member = structType.member(named: name) else {
				return .error(
					[Diagnostic(message: "No member \(name) for \(receiver)", severity: .error, location: location)]
				)
			}

			context.unify(
				context.applySubstitutions(to: member.asType(in: context)),
				context.applySubstitutions(to: resolvedType),
				location
			)
		case .enumCase(let enumCase):
			context.unify(
				context.applySubstitutions(to: .enumCase(enumCase)),
				resolvedType,
				location
			)
		case .enumType(let enumType):
			guard let member = enumType.cases.first(where: { $0.name == name }) else {
				return .error(
					[Diagnostic(message: "No member \(name) for \(receiver)", severity: .error, location: location)]
				)
			}

			context.unify(
				context.applySubstitutions(to: .enumCase(member)),
				resolvedType,
				location
			)
		case .structInstance(let instance):
			// It's an instance member
			guard var member = instance.member(named: name) else {
				return .error(
					[Diagnostic(message: "No member \(name) for \(receiver)", severity: .error, location: location)]
				)
			}

			if case let .structType(structType) = member {
				member = .structInstance(structType.instantiate(with: instance.substitutions, in: context))
			}

			context.unify(
				context.applySubstitutions(to: member),
				context.applySubstitutions(to: resolvedType),
				location
			)
		case .selfVar(let structType):
			guard var member = structType.member(named: name) else {
				return .error(
					[Diagnostic(message: "No member \(name) for \(receiver)", severity: .error, location: location)]
				)
			}

			if case let .structType(structType) = member.asType(in: context) {
				member = .type(.structInstance(structType.instantiate(with: [:], in: context)))
			}

			context.unify(
				context.applySubstitutions(to: resolvedType),
				context.applySubstitutions(to: member.asType(in: context)),
				location
			)

			context.unify(
				context.applySubstitutions(to: member.asType(in: context)),
				context.applySubstitutions(to: resolvedType),
				location
			)
		default:
			return .error([
				Diagnostic(
					message: "Receiver not a struct instance. Got: \(receiver)",
					severity: .error,
					location: location
				)
			])
		}

		return .ok
	}
}
