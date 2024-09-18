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
	var isRetry: Bool

	func result(in context: InferenceContext) -> String {
		let receiver =
			receiver.asType(in: context)

		let type = context.applySubstitutions(to: type.asType(in: context))

		return "MemberConstraint(receiver: \(receiver.debugDescription), name: \(name), type: \(type.debugDescription))"
	}

	func resolveReceiver(_ receiver: InferenceResult?) -> InferenceResult {
		if let receiver {
			return receiver
		}

		return .type(.any)
	}

	var description: String {
		"MemberConstraint(receiver: \(receiver.debugDescription), name: \(name), type: \(type.debugDescription))"
	}

	var location: SourceLocation

	func solve(in context: InferenceContext) -> ConstraintCheckResult {
		let receiver = context.applySubstitutions(to: resolveReceiver(receiver).asType(in: context))
		return resolve(
			withReceiver: receiver,
			name: name,
			type: type.asType(in: context),
			in: context
		)
	}

	func resolve(withReceiver receiver: InferenceType, name: String, type: InferenceType, in context: InferenceContext) -> ConstraintCheckResult {
		let resolvedType = context.applySubstitutions(to: type)

		switch context.applySubstitutions(to: receiver) {
		case let .structType(structType):
			// It's a type parameter, try to unify it with a property
			guard let member = structType.member(named: name, in: context) else {
				return .error(
					[Diagnostic(message: "No member \(name) for \(receiver)", severity: .error, location: location)]
				)
			}

			context.unify(
				context.applySubstitutions(to: member.asType(in: context)),
				context.applySubstitutions(to: resolvedType),
				location
			)
		case let .enumCase(enumCase):
			context.unify(
				context.applySubstitutions(to: .enumCase(enumCase)),
				resolvedType,
				location
			)
		case let .enumType(enumType):
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
		case let .structInstance(instance):
			// It's an instance member
			guard var member = instance.member(named: name, in: context) else {
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
		case let .selfVar(.structType(type)):
			guard var member = type.typeContext.member(named: name) else {
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
		case let .selfVar(.enumType(type)):
			guard var member = type.typeContext.member(named: name) else {
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
		case let .boxedInstance(protocolType):
			guard let member = protocolType.member(named: name, in: context) else {
				return .error(
					[Diagnostic(message: "No member \(name) for \(receiver)", severity: .error, location: location)]
				)
			}

			context.unify(
				context.applySubstitutions(to: resolvedType),
				context.applySubstitutions(to: member),
				location
			)

			context.unify(
				context.applySubstitutions(to: member),
				context.applySubstitutions(to: resolvedType),
				location
			)
		default:
			if isRetry {
				return .error([
					Diagnostic(
						message: "Receiver not an instance. Got: \(receiver.debugDescription)",
						severity: .error,
						location: location
					),
				])
			} else {
				var deferred = self
				deferred.isRetry = true
				context.deferConstraint(deferred)
			}
		}

		return .ok
	}
}
