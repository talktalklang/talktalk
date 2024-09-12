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

public protocol Instantiatable: Equatable, Hashable {
	var name: String { get }

	func member(named name: String, in context: InferenceContext) -> InferenceResult?
}

public class Instance<Kind: Instantiatable>: Equatable, Hashable, CustomStringConvertible {
	public static func == (lhs: Instance, rhs: Instance) -> Bool {
		lhs.type == rhs.type && lhs.substitutions == rhs.substitutions
	}

	let id: Int
	public let type: Kind
	var substitutions: [TypeVariable: InferenceType]

	public static func extract(from type: InferenceType) -> Instance<StructType>? {
		if case let .structInstance(instance) = type {
			return instance
		}

		return nil
	}

	public static func synthesized(_ type: Kind) -> Instance {
		Instance(id: -9999, type: type, substitutions: [:])
	}

	init(id: Int, type: Kind, substitutions: [TypeVariable : InferenceType]) {
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

	func member(named name: String, in context: InferenceContext) -> InferenceType? {
		guard let structMember = type.member(named: name, in: context) else {
			return nil
		}

		var instanceMember: InferenceType
		switch structMember {
		case .scheme(let scheme):
			// It's a method
			let type = context.instantiate(scheme: scheme)
			instanceMember = context.applySubstitutions(to: type, with: substitutions)
		case .type(let inferenceType):
			// It's a property
			instanceMember = context.applySubstitutions(to: inferenceType, with: substitutions)
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

public indirect enum InferenceType: Equatable, Hashable, CustomStringConvertible, CustomDebugStringConvertible {
	// Something we'll fill in later.
	case typeVar(TypeVariable)

	// Primitives, like int or string
	case base(Primitive)

	// Function type. Also used for methods. The first type is args, the second is return type.
	case function([InferenceType], InferenceType)

	// Struct stuff
	case structType(StructType)
	case structInstance(Instance<StructType>)

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
	case enumCase(EnumCase)
	case enumCaseInstance(Instance<EnumCase>)

	// Pattern matching (type, associated values)
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
		case let .enumCaseInstance(instance):
			"\(instance)"
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
		case let .enumCase(kase):
			kase.description
		case let .pattern(pattern):
			"pattern: \(pattern)"
		case .void:
			"void"
		}
	}

	public var debugDescription: String {
		switch self {
		case let .enumCaseInstance(instance):
			"\(instance)"
		case .protocol(let protocolType):
			"\(protocolType.name).Protocol"
		case .typeVar(let typeVariable):
			typeVariable.debugDescription
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
		case let .enumCase(kase):
			kase.description
		case let .pattern(pattern):
			"pattern: \(pattern)"
		case .void:
			"void"
		}
	}
}
