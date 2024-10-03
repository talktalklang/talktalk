//
//  InferenceResult.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/25/24.
//

public typealias Substitutions = [TypeVariable: InferenceType]

public struct InstantiatedResult {
	let type: InferenceType
	let variables: [TypeVariable: InferenceType]
}

extension Dictionary<TypeVariable, InferenceType> {
	var asResults: [TypeVariable: InferenceResult] {
		reduce(into: [:]) {
			$0[$1.key] = .type($1.value)
		}
	}
}

public enum InferenceResult: Equatable, Hashable, CustomStringConvertible, CustomDebugStringConvertible {
	case scheme(Scheme), type(InferenceType)

	func instantiate(
		in context: Context,
		with substitutions: [TypeVariable: InferenceType] = [:],
		file: String = #file,
		line: UInt32 = #line
	) -> InstantiatedResult {
		let (type, variables): (InferenceType, [TypeVariable: InferenceType])
		switch self {
		case .scheme(let scheme):
			(type, variables) = context.instantiate(scheme, with: substitutions, file: file, line: line)
		case .type(let inferenceType):
			if case let .typeVar(typeVar) = inferenceType, let substitution = substitutions[typeVar] {
				(type, variables) = (substitution, substitutions)
			} else {
				(type, variables) = (inferenceType, substitutions)
			}
		}

		return InstantiatedResult(type: type, variables: variables)
	}

	var isResolved: Bool {
		switch self {
		case .type(.typeVar(_)): return false
		default: return true
		}
	}

	public var mangled: String {
		switch self {
		case let .scheme(scheme):
			"scheme(\(scheme.type.mangled))"
		case let .type(inferenceType):
			inferenceType.mangled
		}
	}

	public var description: String {
		switch self {
		case let .scheme(scheme):
			"scheme(\(scheme))"
		case let .type(inferenceType):
			inferenceType.description
		}
	}

	public var debugDescription: String {
		switch self {
		case let .scheme(scheme):
			"scheme(\(scheme.debugDescription))"
		case let .type(inferenceType):
			inferenceType.debugDescription
		}
	}

	var asType: InferenceType? {
		if case let .type(inferenceType) = self {
			return inferenceType
		}

		return nil
	}

	// Variance helpers
	func covariant(with rhs: InferenceResult, in context: InferenceContext) -> Bool {
		switch (self, rhs) {
		case let (.scheme(lhs), .scheme(rhs)):
			lhs.type.covariant(with: rhs.type, in: context)
		case let (.type(lhs), .type(rhs)):
			lhs.covariant(with: rhs, in: context)
		case let (.type(lhs), .scheme(rhs)):
			lhs.covariant(with: rhs.type, in: context)
		case let (.scheme(lhs), .type(rhs)):
			lhs.type.covariant(with: rhs, in: context)
		}
	}

	public func asType(in context: InferenceContext) -> InferenceType {
		switch self {
		case let .scheme(scheme):
			context.instantiate(scheme: scheme)
		case let .type(inferenceType):
			inferenceType
		}
	}
}
