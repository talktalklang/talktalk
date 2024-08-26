//
//  Type.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/25/24.
//

struct StructType: Equatable, Hashable {
	static func ==(lhs: StructType, rhs: StructType) -> Bool {
		lhs.name == rhs.name && lhs.parameters == rhs.parameters
	}

	let name: String
	let parameters: [InferenceType]
	let methods: [String: InferenceResult]
	let properties: [String: InferenceResult]
	let initializers: [String: InferenceResult]
	let context: InferenceContext

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
		hasher.combine(parameters)
	}
}

indirect enum InferenceType: Equatable, Hashable, CustomStringConvertible {
	case typeVar(TypeVariable)
	case base(Primitive) // primitives
	case function([InferenceType], InferenceType)
	case structType(StructType)
	case structInstance(StructType)
	case error(InferenceError)
	case void

	static func typeVar(_ name: String, _ id: VariableID) -> InferenceType {
		InferenceType.typeVar(TypeVariable(name, id))
	}

	var description: String {
		switch self {
		case .typeVar(let typeVariable):
			"typeVariable(\(typeVariable))"
		case .base(let primitive):
			"\(primitive)"
		case .function(let vars, let inferenceType):
			"function(\(vars.map(\.description).joined(separator: ", "))), returns(\(inferenceType))"
		case .error(let error):
			"error(\(error))"
		case .structType(let structType):
			structType.name + ".Type"
		case .structInstance(let structType):
			structType.name
		case .void:
			"void"
		}
	}
}
