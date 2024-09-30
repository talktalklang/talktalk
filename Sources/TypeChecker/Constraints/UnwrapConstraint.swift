//
//  UnwrapConstraint.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/29/24.
//
import TalkTalkCore

struct UnwrapConstraint: Constraint {
	let typeVar: InferenceType
	let wrapped: InferenceResult
	let location: SourceLocation
	var isRetry: Bool = false

	func result(in context: InferenceContext) -> String {
		let typeVar = context.applySubstitutions(to: typeVar)
		return "UnwrapConstraint(typeVar: \(typeVar.debugDescription))"
	}

	var description: String {
		"UnwrapConstraint(typeVar: \(typeVar.debugDescription))"
	}

	func solve(in context: InferenceContext) -> ConstraintCheckResult {
		let type = context.applySubstitutions(to: typeVar)

		if case let .instance(.enumType(instance)) = context.applySubstitutions(to: wrapped),
			 instance.type.name == "Optional",
			 let wrapped = instance.substitutions.values.first,
			 case let .typeVar(typeVariable) = type {
			if case let .instantiatable(instantiatableType) = wrapped {
				let wrappedInstance = instantiatableType.instantiate(with: instance.substitutions, in: context)
//				context.bind(typeVar: typeVariable, to: .instance(wrappedInstance))
//				context.unify(.instance(wrappedInstance), typeVar, location)
			} else {
//				context.unify(wrapped, typeVar, location)
//				context.bind(typeVar: typeVariable, to: wrapped)
			}

			return .ok
		}

		if case .typeVar = type, !isRetry {
			context.deferConstraint(UnwrapConstraint(typeVar: type, wrapped: wrapped, location: location, isRetry: true))
			return .ok
		} else {
			return .error([
				.init(message: "Cannot unwrap non-optional type: \(type)", severity: .error, location: location)
			])
		}
	}
}
