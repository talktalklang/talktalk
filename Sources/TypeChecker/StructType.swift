//
//  StructType.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/26/24.
//

struct StructType: Equatable, Hashable, CustomStringConvertible {
	static func ==(lhs: StructType, rhs: StructType) -> Bool {
		lhs.name == rhs.name && lhs.typeContext.properties == rhs.typeContext.properties
	}

	let name: String
	let context: InferenceContext
	let typeContext: TypeContext

	static func extractType(from result: InferenceResult?) -> StructType? {
		if case let .type(.structType(structType)) = result {
			return structType
		}

		return nil
	}

	static func extractInstance(from result: InferenceResult?) -> StructType? {
		if case let .type(.structInstance(structType)) = result {
			return structType
		}

		return nil
	}

	func hash(into hasher: inout Hasher) {
		hasher.combine(name)
		hasher.combine(typeContext.initializers)
		hasher.combine(typeContext.properties)
		hasher.combine(typeContext.methods)
	}

	var description: String {
		"\(name)(\(properties.reduce(into: "") { res, pair in res += "\(pair.key): \(pair.value)" }))"
	}

	var initializers: [String: InferenceResult] {
		typeContext.initializers
	}

	func memberForInstance(named name: String) -> InferenceResult? {
		instanceProperty(named: name) ?? method(named: name)
	}

	func member(named name: String) -> InferenceResult? {
		if let member = properties[name] ?? methods[name] {
			return .type(context.applySubstitutions(to: member.asType(in: context)))
		}

		return nil
	}

	func instanceProperty(named name: String) -> InferenceResult? {
		if let member = properties[name] {
			let result = context.applySubstitutions(to: member.asType(in: context))

			if case let .structType(structType) = result {
				return .type(.structInstance(structType))
			} else {
				return .type(result)
			}
		}

		return nil
	}

	func method(named name: String) -> InferenceResult? {
		if let member = methods[name] {
			return .type(context.applySubstitutions(to: member.asType(in: context)))
		}

		return nil
	}

	var properties: [String: InferenceResult] {
		typeContext.properties
	}

	var methods: [String: InferenceResult] {
		typeContext.methods
	}
}
