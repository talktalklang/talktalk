//
//  TypeConformanceConstraint.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/27/24.
//

import TalkTalkSyntax

struct TypeConformanceConstraint: Constraint {
	let type: InferenceResult
	let conformsTo: InferenceResult

	func result(in context: InferenceContext) -> String {
		let type = context.applySubstitutions(to: type)
		let conformsTo = context.applySubstitutions(to: conformsTo)
		return "TypeConformanceConstraint(type: \(type.debugDescription), conformsTo: \(conformsTo.debugDescription))"
	}

	var description: String {
		"TypeConformanceConstraint(type: \(type.debugDescription), conformsTo: \(conformsTo.debugDescription))"
	}

	var location: SourceLocation

	func solve(in context: InferenceContext) -> ConstraintCheckResult {
		guard case let .protocol(protocolType) = conformsTo.asType else {
			return .error([
				Diagnostic(message: "\(conformsTo) is not a protocol", severity: .error, location: location)
			])
		}

		let type = context.applySubstitutions(to: type)
		switch type {
		case .structType(let structType):
			if !structType.conformances.contains(protocolType) {
				return .error([
					Diagnostic(message: "\(structType.name) does not conform to \(conformsTo)", severity: .error, location: location)
				])
			}

			return .ok
		case .structInstance(let instance):
			if !instance.type.conformances.contains(protocolType) {
				return .error([
					Diagnostic(message: "\(instance.type.name) does not conform to \(conformsTo)", severity: .error, location: location)
				])
			}

			return .ok
		case .enumType(let enumType):
			if !enumType.conformances.contains(protocolType) {
				return .error([
					Diagnostic(message: "\(enumType.name) does not conform to \(conformsTo)", severity: .error, location: location)
				])
			}

			return .ok
		case .enumCase(let enumCase):
			if !enumCase.type.conformances.contains(protocolType) {
				return .error([
					Diagnostic(message: "\(enumCase.type.name) does not conform to \(conformsTo)", severity: .error, location: location)
				])
			}

			return .ok
		default:
			()
		}

		return .error([
			Diagnostic(message: "\(type) does not conform to \(conformsTo)", severity: .error, location: location)
		])
	}
}
