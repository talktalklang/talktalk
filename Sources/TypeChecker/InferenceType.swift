//
//  Type.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/25/24.
//
import Foundation
struct ProtocolType: Equatable, Hashable {
	let name: String
}

class Instance: Equatable, Hashable, CustomStringConvertible {
	static func == (lhs: Instance, rhs: Instance) -> Bool {
		lhs.type == rhs.type && lhs.substitutions == rhs.substitutions
	}

	let id: Int
	let type: StructType
	var substitutions: [TypeVariable: InferenceType]

	static func extract(from type: InferenceType) -> Instance? {
		if case let .structInstance(instance) = type {
			return instance
		}

		return nil
	}

	init(id: Int, type: StructType, substitutions: [TypeVariable : InferenceType]) {
		self.id = id
		self.type = type
		self.substitutions = substitutions
	}

	func member(named name: String) -> InferenceType? {
		guard let structMember = type.member(named: name) else {
			return nil
		}

		var instanceMember: InferenceType
		switch structMember {
		case .scheme(let scheme):
			// It's a method
			let type = type.context.instantiate(scheme: scheme)
			instanceMember = self.type.context.applySubstitutions(to: type, with: substitutions)
		case .type(let inferenceType):
			// It's a property
			instanceMember = self.type.context.applySubstitutions(to: inferenceType, with: substitutions)
		}

		return instanceMember
	}

	var description: String {
		"\(type.name)()#\(id)"
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(type)
		hasher.combine(substitutions)
	}
}

indirect enum InferenceType: Equatable, Hashable, CustomStringConvertible {
	case typeVar(TypeVariable)
	case base(Primitive) // primitives
	case function([InferenceType], InferenceType)
	case structType(StructType)
	case structInstance(Instance)
	case `protocol`(ProtocolType)
	case member(InferenceType, String)
	case error(InferenceError)
	case void

	static func typeVar(_ name: String, _ id: VariableID) -> InferenceType {
		InferenceType.typeVar(TypeVariable(name, id))
	}

	var description: String {
		switch self {
		case .protocol(let protocolType):
			"\(protocolType.name).Protocol"
		case .typeVar(let typeVariable):
			typeVariable.description
		case .base(let primitive):
			"\(primitive)"
		case .function(let vars, let inferenceType):
			"function(\(vars.map(\.description).joined(separator: ", "))), returns(\(inferenceType))"
		case .error(let error):
			"error(\(error))"
		case .structType(let structType):
			structType.name + ".Type"
		case .structInstance(let instance):
			instance.description
		case .member(let type, let name):
			"\(type).\(name)"
		case .void:
			"void"
		}
	}
}
