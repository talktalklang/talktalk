//
//  TypeConformanceConstraint.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/27/24.
//

import TalkTalkSyntax

public struct ConformanceRequirement: Hashable {
	public let name: String
	public let type: InferenceType

	func satisfied(by type: any Instantiatable, in context: InferenceContext) -> Bool {
		guard let member = type.member(named: name, in: context) else {
			return false
		}

		return member.asType(in: context) <= self.type
	}
}

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
		guard case let .instantiatable(.protocol(protocolType)) = conformsTo.asType(in: context) else {
			return .error([
				Diagnostic(message: "\(conformsTo) is not a protocol", severity: .error, location: location),
			])
		}

		let type = context.applySubstitutions(to: type)
		switch type {
		case let .instantiatable(type):
			return checkConformance(of: type.extract(), to: protocolType, in: type.context)
		case let .instance(instance):
			return checkConformance(of: instance.type, to: protocolType, in: instance.type.context)
		case let .enumCase(enumCase):
			return checkConformance(of: enumCase.type, to: protocolType, in: context)
		default:
			()
		}

		return .error([
			Diagnostic(message: "\(type) does not conform to \(conformsTo)", severity: .error, location: location),
		])
	}

	func checkConformance(of type: any Instantiatable, to protocolType: ProtocolType, in context: InferenceContext) -> ConstraintCheckResult {
		for typeRequirement in protocolType.typeContext.typeParameters {
			// Unify struct's generic types with protocol type requirements
			if let typeParam = type.typeParameters.first(where: {
				$0.name == typeRequirement.name
			}) {
				context.unify(.typeVar(typeRequirement), .typeVar(typeParam), location)
			}
		}

		// TODO: We could probably cache this on the struct type instead of calculating it all the time
		var missingRequirements: Set<ConformanceRequirement> = []
		for requirement in protocolType.requirements(in: context) {
			if !requirement.satisfied(by: type, in: context) {
				missingRequirements.insert(requirement)
			}
		}

		if missingRequirements.isEmpty {
			return .ok
		} else {
			var missing = "\n"
			for requirement in missingRequirements {
				missing += "\t\(requirement.name) \(requirement.type)\n"

				if let maybe = type.member(named: requirement.name, in: context) {
					missing += "\t- did you mean \(requirement.name) \(maybe)\n"
				}
			}
			return .error([
				Diagnostic(message: "\(type.name) does not conform to \(conformsTo). Missing: \(missing)", severity: .error, location: location),
			])
		}
	}
}
