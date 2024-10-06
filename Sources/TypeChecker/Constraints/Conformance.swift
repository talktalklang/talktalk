//
//  Conformance.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 10/5/24.
//

import TalkTalkCore

struct ConformanceRequirement: Hashable {
	let name: String
	let type: InferenceResult

	func satisfied<T: MemberOwner>(by conformee: T, in context: Context) -> Bool {
		guard let member = conformee.member(named: name) else {
			return false
		}

		// If we have a known base type, we can add a constraint on it so it gets resolved later
		if case let .resolved(.base(base)) = type {
			context.addConstraint(
				Constraints.Equality(
					context: context,
					lhs: member,
					rhs: .resolved(.base(base)),
					location: [.synthetic(.less)]
				)
			)
		}

		return member.covariant(with: type, in: context)
	}
}

extension Constraints {
	struct Conformance: Constraint {
		let context: Context
		let type: InferenceResult
		let conformsTo: InferenceResult
		var retries: Int = 0
		let location: SourceLocation

		var before: String {
			"Conformance(type: \(type.debugDescription), type: \(conformsTo.debugDescription), location: \(location))"
		}

		var after: String {
			let conformsTo = context.applySubstitutions(to: conformsTo)
			return "Conformance(type: \(type.debugDescription), type: \(conformsTo.debugDescription), location: \(location))"
		}

		func extract(type: InferenceResult) throws -> InstanceWrapper {
			guard case let .instance(type) = type.asInstance(in: context, with: [:]) else {
				throw TypeError.typeError("Unable to extract type from \(type)")
			}

			return type
		}

		func solve() throws {
			let conformsTo = context.applySubstitutions(to: conformsTo.asInstance(in: context, with: [:]))

			guard case let .instance(.protocol(conformsToInstance)) = conformsTo else {
				context.error("Cannot conform to non protocol: \(conformsTo.debugDescription)", at: location)
				return
			}

			let instance = try extract(type: type)
			let type = instance.type
			let conformsToType = conformsToInstance.type

			var missingRequirements: Set<ConformanceRequirement> = []
			for requirement in conformsToType.requirements(in: context) {
				if !requirement.satisfied(by: type, in: context) {
					missingRequirements.insert(requirement)
				}
			}

			if missingRequirements.isEmpty {
				return
			}

			let subdiagnostics = missingRequirements.map { requirement in
				var message = "Missing \(requirement.name): \(requirement.type.debugDescription)."

				if let member = type.member(named: requirement.name) {
					message += " Did you mean \(member.debugDescription)"
				}

				return Diagnostic(message: message, severity: .error, subdiagnostics: [], location: location)
			}
			
			let diagnostic = Diagnostic(message: "\(type.name) does not conform to \(conformsToType.name)", severity: .error, subdiagnostics: subdiagnostics, location: location)

			context.diagnostic(diagnostic)
		}
	}
}
