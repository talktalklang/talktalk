//
//  Type.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/25/24.
//
import Foundation
import OrderedCollections

public struct ProtocolType: Equatable, Hashable, Instantiatable {
	public static func == (lhs: Self, rhs: Self) -> Bool {
		lhs.name == rhs.name && lhs.typeContext.properties == rhs.typeContext.properties
	}

	public let name: String
	public let context: InferenceContext
	public let typeContext: TypeContext
	public var conformances: [ProtocolType] { typeContext.conformances }

	public func hash(into hasher: inout Hasher) {
		hasher.combine(name)
		hasher.combine(typeContext.properties)
		hasher.combine(typeContext.methods)
	}

	public func missingConformanceRequirements(for type: any Instantiatable, in context: InferenceContext) -> Set<ConformanceRequirement> {
		var missingRequirements: Set<ConformanceRequirement> = []

		for requirement in requirements(in: context) {
			if !requirement.satisfied(by: type, in: context) {
				missingRequirements.insert(requirement)
			}
		}

		return missingRequirements
	}

	public func requirements(in context: InferenceContext) -> Set<ConformanceRequirement> {
		var result: Set<ConformanceRequirement> = []

		for (name, type) in typeContext.methods {
			result.insert(.init(name: name, type: context.applySubstitutions(to: type)))
		}

		for (name, type) in typeContext.properties {
			result.insert(.init(name: name, type: context.applySubstitutions(to: type)))
		}
		
		return result
	}

	public static func extract(from type: InferenceType) -> ProtocolType? {
		if case let .protocol(type) = type {
			return type
		}

		return nil
	}

	public func member(named name: String, in context: InferenceContext) -> InferenceResult? {
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

	// Struct stuff
	case structType(StructType)
	case structInstance(Instance<StructType>)

	// When we expect a type but can't establish one yet
	case placeholder(TypeVariable)

	// A protocol Type
	case `protocol`(ProtocolType)
	case boxedInstance(Instance<ProtocolType>)

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
		case let .boxedInstance(instance):
			"\(instance)"
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
		case let .structInstance(instance):
			instance.debugDescription
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
		case let .boxedInstance(instance):
			"\(instance)"
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
		case let (.structInstance(lhs), .protocol(protocolType)):
			return protocolType.missingConformanceRequirements(for: lhs.type, in: lhs.type.context).isEmpty
		case let (.enumCase(lhs), .protocol(protocolType)):
			return protocolType.missingConformanceRequirements(for: lhs.type, in: lhs.type.context).isEmpty
		case let (.boxedInstance(lhs), .protocol(protocolType)):
			return protocolType.missingConformanceRequirements(for: lhs.type, in: lhs.type.context).isEmpty
		default:
			return lhs == rhs
		}
	}
}
