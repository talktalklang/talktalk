//
//  Type.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/25/24.
//

struct ProtocolType: Equatable, Hashable {
	let name: String
}

indirect enum InferenceType: Equatable, Hashable, CustomStringConvertible {
	case typeVar(TypeVariable)
	case base(Primitive) // primitives
	case function([InferenceType], InferenceType)
	case structType(StructType)
	case instance(Instance)
	case `protocol`(ProtocolType)
	case error(InferenceError)
	case void

	static func typeVar(_ name: String, _ id: VariableID) -> InferenceType {
		InferenceType.typeVar(TypeVariable(name, id))
	}

	var description: String {
		switch self {
		case .protocol(let protocolType):
			"\(protocolType.name).Type"
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
		case .instance(let instance):
			instance.type.name
		case .void:
			"void"
		}
	}
}
