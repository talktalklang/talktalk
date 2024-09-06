//
//  Type.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/25/24.
//
import Foundation
public struct ProtocolType: Equatable, Hashable {
	public let name: String
}

public class Instance: Equatable, Hashable, CustomStringConvertible {
	public static func == (lhs: Instance, rhs: Instance) -> Bool {
		lhs.type == rhs.type && lhs.substitutions == rhs.substitutions
	}

	let id: Int
	public let type: StructType
	var substitutions: [TypeVariable: InferenceType]

	public static func extract(from type: InferenceType) -> Instance? {
		if case let .structInstance(instance) = type {
			return instance
		}

		return nil
	}

	public static func synthesized(_ type: StructType) -> Instance {
		Instance(id: -9999, type: type, substitutions: [:])
	}

	init(id: Int, type: StructType, substitutions: [TypeVariable : InferenceType]) {
		self.id = id
		self.type = type
		self.substitutions = substitutions
	}

	public func relatedType(named name: String) -> InferenceType? {
		for substitution in substitutions.keys {
			if substitution.name == name {
				return substitutions[substitution]
			}
		}

		return nil
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

	public var description: String {
		if substitutions.isEmpty {
			"\(type.name)()#\(id)"
		} else {
			"\(type.name)<\(substitutions.keys.map(\.description).joined(separator: ", "))>()#\(id)"
		}
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(type)
		hasher.combine(substitutions)
	}
}

public indirect enum InferenceType: Equatable, Hashable, CustomStringConvertible {
	// Something we'll fill in later.
	case typeVar(TypeVariable)

	// Primitives, like int or string
	case base(Primitive)

	// Function type. Also used for methods. The first type is args, the second is return type.
	case function([InferenceType], InferenceType)

	// Struct stuff
	case structType(StructType)
	case structInstance(Instance)

	// When we expect a type but can't establish one yet
	case placeholder(TypeVariable)

	// A protocol Type
	case `protocol`(ProtocolType)

	// Errors
	case error(InferenceError)

	// Used for Type expressions that refer to actual types
	case kind(InferenceType)

	// Used for `self` in types that support it
	case selfVar(StructType)

	// Enum types
	case enumType(EnumType)
	case enumCase(EnumType, EnumCase)

	// Pattern matching
	case pattern(Pattern)

	// When we can't figure it out or don't care
	case any

	// The absence of a type
	case void

	static func typeVar(_ name: String, _ id: VariableID) -> InferenceType {
		InferenceType.typeVar(TypeVariable(name, id))
	}

	public var description: String {
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
		case .kind(let type):
			"\(type).Kind"
		case .structInstance(let instance):
			instance.description
		case .any:
			"any"
		case let .selfVar(type):
			"\(type.description) (self)"
		case let .placeholder(variable):
			"\(variable) (placeholder)"
		case let .enumType(type):
			type.description
		case let .enumCase(_, kase):
			kase.description
		case let .pattern(pattern):
			"pattern: \(pattern)"
		case .void:
			"void"
		}
	}
}
