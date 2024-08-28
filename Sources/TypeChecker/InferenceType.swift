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
	static func ==(lhs: InferenceType, rhs: InferenceType) -> Bool {
		switch (lhs, rhs) {
		case let (.typeVar(lhs), .typeVar(rhs)):
			lhs.id == rhs.id
		case let (.base(lhs), .base(rhs)):
			lhs == rhs
		case let (.function(lhsParams, lhsReturns), .function(rhsParams, rhsReturns)):
			lhsParams == rhsParams && lhsReturns == rhsReturns
		case let (.structType(lhs), .structType(rhs)):
			lhs == rhs
		case let (.structInstance(lhs), .structInstance(rhs)):
			lhs == rhs
		case let (.protocol(lhs), .protocol(rhs)):
			lhs == rhs
		case let (.error(lhs), .error(rhs)):
			lhs == rhs
		case (.void, .void):
			true
		case let (.anyTypeVar(named: name), .typeVar(rhs)):
			name == rhs.name
		case let (.typeVar(lhs), .anyTypeVar(named: name)):
			lhs.name == name
		default:
			false
		}
	}

	case typeVar(TypeVariable)
	case base(Primitive) // primitives
	case function([InferenceType], InferenceType)
	case structType(StructType)
	case structInstance(StructType)
	case `protocol`(ProtocolType)
	case error(InferenceError)
	case void

	case anyTypeVar(named: String)

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
		case .structInstance(let structType):
			structType.name
		case .void:
			"void"
		case let .anyTypeVar(named: name):
			"anyTypeVar(\(name))"
		}
	}
}
