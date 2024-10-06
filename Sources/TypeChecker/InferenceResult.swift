//
//  InferenceResult.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/25/24.
//

import TalkTalkCore

public typealias Substitutions = [TypeVariable: InferenceType]

public struct InstantiatedResult {
	let type: InferenceType
	let variables: [TypeVariable: InferenceType]
}

extension Dictionary<TypeVariable, InferenceType> {
	var asResults: [TypeVariable: InferenceResult] {
		reduce(into: [:]) {
			$0[$1.key] = .resolved($1.value)
		}
	}
}

public enum InferenceResult: Equatable, Hashable, CustomStringConvertible, CustomDebugStringConvertible {
	case scheme(Scheme), resolved(InferenceType)

	public static func optional(_ type: InferenceResult) -> InferenceResult {
		let optionalType = Library.standard.files.first(where: { $0.path.contains("Optional.talk") })!
		let context = try! ContextVisitor.visit(Parser.parse(optionalType), module: "Standard")

		let enumType = Enum.extract(from: context.type(named: "Optional")!.instantiate(in: context).type)!
		let wrapped = enumType.typeParameters["Wrapped"]!
		let instance = enumType.instantiate(with: [wrapped: type.instantiate(in: context).type])
		return .resolved(.instance(.enum(instance)))
	}

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
		case .resolved(let inferenceType):
			if case let .typeVar(typeVar) = inferenceType, let substitution = substitutions[typeVar] {
				(type, variables) = (substitution, substitutions)
			} else {
				(type, variables) = (inferenceType, substitutions)
			}
		}

		return InstantiatedResult(type: type, variables: variables)
	}

	func asInstance(in context: Context, with substitutions: [TypeVariable: InferenceType], file: String = #file, line: UInt32 = #line) -> InferenceType {
		let instantiated = instantiate(in: context, with: substitutions).type
		if case let .type(type) = instantiated {
			return .instance(type.instantiate(with: substitutions))
		} else {
			return instantiated
		}
	}

	var isResolved: Bool {
		switch self {
		case .resolved(.typeVar(_)): return false
		default: return true
		}
	}

	public var mangled: String {
		switch self {
		case let .scheme(scheme):
			"scheme(\(scheme.type.mangled))"
		case let .resolved(inferenceType):
			inferenceType.mangled
		}
	}

	public var description: String {
		switch self {
		case let .scheme(scheme):
			"scheme(\(scheme))"
		case let .resolved(inferenceType):
			inferenceType.description
		}
	}

	public var debugDescription: String {
		switch self {
		case let .scheme(scheme):
			"scheme(\(scheme.debugDescription))"
		case let .resolved(inferenceType):
			inferenceType.debugDescription
		}
	}

	// Variance helpers
	func covariant(with rhs: InferenceResult, in context: Context) -> Bool {
		switch (self, rhs) {
		case let (.scheme(lhs), .scheme(rhs)):
			lhs.type.covariant(with: rhs.type, in: context)
		case let (.resolved(lhs), .resolved(rhs)):
			lhs.covariant(with: rhs, in: context)
		case let (.resolved(lhs), .scheme(rhs)):
			lhs.covariant(with: rhs.type, in: context)
		case let (.scheme(lhs), .resolved(rhs)):
			lhs.type.covariant(with: rhs, in: context)
		}
	}
}
