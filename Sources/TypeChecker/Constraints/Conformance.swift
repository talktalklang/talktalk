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
	struct Conformance<T: MemberOwner>: Constraint {
		let context: Context
		let type: T
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

		func solve() throws {
			guard case let .type(.protocol(conformsTo)) = context.applySubstitutions(to: conformsTo) else {
				context.error("Cannot conform to non protocol: \(conformsTo)", at: location)
				return
			}

			var missingRequirements: Set<ConformanceRequirement> = []
			for requirement in conformsTo.requirements(in: context) {
				if !requirement.satisfied(by: type, in: context) {
					missingRequirements.insert(requirement)
				}
			}

			if missingRequirements.isEmpty {
				return
			}

			let subdiagnostics = missingRequirements.map { requirement in
				Diagnostic(message: "Missing \(requirement.name): \(requirement.type.description)", severity: .error, subdiagnostics: [], location: location)
			}
			let diagnostic = Diagnostic(message: "\(type.name) does not conform to \(conformsTo.name)", severity: .error, subdiagnostics: subdiagnostics, location: location)

			context.diagnostics.append(diagnostic)
		}
	}
}
