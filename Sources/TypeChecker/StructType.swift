//
//  StructType.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/26/24.
//

struct StructType: Equatable, Hashable, CustomStringConvertible {
	struct Initializer: Equatable, Hashable {
		// The type of the init func itself
		var initializationType: InferenceResult

		// A map of arguments to parameters. This lets us populate generic
		// parameters on init. For example:
		//
		//	struct Wrapper<T> {
		//		var wrapped: T
		//
		//		init(wrapped: T) {
		//			self.wrapped = wrapped
		//		}
		//	}
		//
		// In this case we'd add ["wrapped": "T"] to the initialization parameters
		// so that the type variable for wrapped can be unified with T's.
		var initializationParameters: [String: InferenceType]
	}

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

	var initializers: [String: Initializer] {
		typeContext.initializers
	}

	var properties: [String: InferenceResult] {
		typeContext.properties
	}

	var methods: [String: InferenceResult] {
		typeContext.methods
	}
}
