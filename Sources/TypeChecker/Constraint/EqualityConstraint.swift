//
//  EqualityConstraint.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/27/24.
//

import TalkTalkCore

struct EqualityConstraint: InferenceConstraint {
	let lhs: InferenceResult
	let rhs: InferenceResult
	let location: SourceLocation

	let file: String
	let line: UInt32

	func result(in context: InferenceContext) -> String {
		let lhs = context.applySubstitutions(to: lhs.asType(in: context))
		let rhs = context.applySubstitutions(to: rhs.asType(in: context))

		return "EqualityConstraint(lhs: \(lhs.debugDescription), rhs: \(rhs.debugDescription), location: \(location)"
	}

	var description: String {
		"EqualityConstraint(lhs: \(lhs.debugDescription), rhs: \(rhs.debugDescription), location: \(location))"
	}

	func solve(in context: InferenceContext) -> ConstraintCheckResult {
		let lhs = switch lhs {
		case let .scheme(scheme):
			context.applySubstitutions(to: context.instantiate(scheme: scheme))
		case let .type(type):
			context.applySubstitutions(to: type)
		}

		let rhs = switch rhs {
		case let .scheme(scheme):
			context.applySubstitutions(to: context.instantiate(scheme: scheme))
		case let .type(type):
			context.applySubstitutions(to: type)
		}

		if lhs == rhs {
			return .ok
		}

		context.unify(lhs, rhs, location)

		return .ok
	}
}

extension InferenceConstraint where Self == EqualityConstraint {
	static func equality(
		_ lhs: InferenceResult,
		_ rhs: InferenceResult,
		at location: SourceLocation,
		file: String = #file,
		line: UInt32 = #line
	) -> EqualityConstraint {
		EqualityConstraint(lhs: lhs, rhs: rhs, location: location, file: file, line: line)
	}

	static func equality(
		_ lhs: InferenceType,
		_ rhs: InferenceType,
		at location: SourceLocation,
		file: String = #file,
		line: UInt32 = #line
	) -> EqualityConstraint {
		EqualityConstraint(lhs: .type(lhs), rhs: .type(rhs), location: location, file: file, line: line)
	}
}
