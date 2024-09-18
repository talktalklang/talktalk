//
//  Type.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/25/24.
//
import Foundation
import OrderedCollections

public indirect enum InferenceType: Equatable, Hashable, CustomStringConvertible {
	// Something we'll fill in later.
	case typeVar(TypeVariable)

	// Primitives, like int or string
	case base(Primitive)

	// Function type. Also used for methods. The first type is args, the second is return type.
	case function([InferenceType], InferenceType)

	// Instances
	case instance(Instance)

	// Struct stuff
	case structType(StructType)

	// When we expect a type but can't establish one yet
	case placeholder(TypeVariable)

	// A protocol Type
	case `protocol`(ProtocolType)

	// Errors
	case error(InferenceError)

	// Used for Type expressions that refer to actual types
	case kind(InferenceType)

	// Used for `self` in types that support it
	case selfVar(InferenceType)

	// Enum types
	case enumType(EnumType)
	case enumCase(EnumCase)

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
			"\(instance.debugDescription)"
		case let .protocol(protocolType):
			"\(protocolType.name).Protocol"
		case let .typeVar(typeVariable):
			typeVariable.debugDescription
		case let .base(primitive):
			"\(primitive)"
		case let .function(vars, inferenceType):
			"function(\(vars.map(\.debugDescription).joined(separator: ", "))), returns(\(inferenceType.debugDescription))"
		case let .error(error):
			"error(\(error))"
		case let .structType(structType):
			structType.name + ".Type"
		case let .kind(type):
			"\(type.debugDescription).Kind"
		case .any:
			"any"
		case let .selfVar(type):
			"\(type) (self)"
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
			"\(instance.description)"
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
		case .any:
			"any"
		case let .selfVar(type):
			"\(type) (self)"
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

extension Array where Element == InferenceType {
	static func <=(lhs: [InferenceType], rhs: [InferenceType]) -> Bool {
		if lhs.count != rhs.count {
			return false
		}
		
		for (lhsElement, rhsElement) in zip(lhs, rhs) {
			if !(lhsElement <= rhsElement) {
				return false
			}
		}

		return true
	}
}

// Variance helpers
extension InferenceType {
	static func <=(lhs: InferenceType, rhs: InferenceType) -> Bool {
		switch (lhs, rhs) {
		case let (.function(lhsParams, lhsReturns), .function(rhsParams, rhsReturns)):
			return lhsParams <= rhsParams && lhsReturns <= rhsReturns
		case let (lhs as any Instantiatable, .protocol(protocolType)):
			return protocolType.missingConformanceRequirements(for: lhs, in: lhs.context).isEmpty
		case let (.instance(lhs), .protocol(protocolType)):
			return protocolType.missingConformanceRequirements(for: lhs.type, in: lhs.type.context).isEmpty
		case let (.enumCase(lhs), .protocol(protocolType)):
			return protocolType.missingConformanceRequirements(for: lhs.type, in: lhs.type.context).isEmpty
		default:
			return lhs == rhs
		}
	}
}
