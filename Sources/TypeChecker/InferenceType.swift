//
//  Type.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/25/24.
//
import Foundation
import OrderedCollections

public struct ProtocolType: Equatable, Hashable {
	public static func == (lhs: Self, rhs: Self) -> Bool {
		lhs.name == rhs.name && lhs.typeContext.properties == rhs.typeContext.properties
	}

	public let name: String
	let typeContext: TypeContext

	public func hash(into hasher: inout Hasher) {
		hasher.combine(name)
		hasher.combine(typeContext.properties)
		hasher.combine(typeContext.methods)
	}

	public static func extract(from type: InferenceType) -> ProtocolType? {
		if case let .protocol(type) = type {
			return type
		}

		return nil
	}

	func member(named name: String, in context: InferenceContext) -> InferenceResult? {
		if let member = properties[name] ?? methods[name] {
			return .type(context.applySubstitutions(to: member.asType(in: context)))
		}

		if let typeParam = typeContext.typeParameters.first(where: { $0.name == name }) {
			return .type(.typeVar(typeParam))
		}

		return nil
	}

	func method(named name: String, in context: InferenceContext) -> InferenceResult? {
		if let member = methods[name] {
			return .type(context.applySubstitutions(to: member.asType(in: context)))
		}

		return nil
	}

	public var properties: OrderedDictionary<String, InferenceResult> {
		typeContext.properties
	}

	public var methods: OrderedDictionary<String, InferenceResult> {
		typeContext.methods
	}
}



public indirect enum InferenceType: Equatable, Hashable, CustomStringConvertible {
	// Something we'll fill in later.
	case typeVar(TypeVariable)

	// Primitives, like int or string
	case base(Primitive)

	// Function type. Also used for methods. The first type is args, the second is return type.
	case function([InferenceType], InferenceType)

	case instance(Instance<StructType>)

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
	case enumCaseInstance(EnumCaseInstance)

	// Pattern matching (type, associated values)
	case pattern(Pattern)

	// When we can't figure it out or don't care
	case any

	// The absence of a type
	case void

	static func typeVar(_ name: String, _ id: VariableID) -> InferenceType {
		InferenceType.typeVar(TypeVariable(name, id))
	}

	public var debugDescription: String {
		switch self {
		case let .instance(instance):
			"\(instance)"
		case let .enumCaseInstance(instance):
			"\(instance.enumCase)\(instance.substitutions)"
		case let .protocol(protocolType):
			"\(protocolType.name).Protocol"
		case let .typeVar(typeVariable):
			typeVariable.debugDescription
		case let .base(primitive):
			"\(primitive)"
		case let .function(vars, inferenceType):
			"function(\(vars.map(\.debugDescription).joined(separator: ", "))), returns(\(inferenceType))"
		case let .error(error):
			"error(\(error))"
		case let .structType(structType):
			structType.name + ".Type"
		case let .kind(type):
			"\(type).Kind"
		case let .structInstance(instance):
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

	public var description: String {
		switch self {
		case let .instance(instance):
			"\(instance)"
		case let .enumCaseInstance(instance):
			"\(instance.enumCase)\(instance.substitutions)"
		case let .protocol(protocolType):
			"\(protocolType.name).Protocol"
		case let .typeVar(typeVariable):
			typeVariable.description
		case let .base(primitive):
			"\(primitive)"
		case let .function(vars, inferenceType):
			"function(\(vars.map(\.description).joined(separator: ", "))), returns(\(inferenceType))"
		case let .error(error):
			"error(\(error))"
		case let .structType(structType):
			structType.name + ".Type"
		case let .kind(type):
			"\(type).Kind"
		case let .structInstance(instance):
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
