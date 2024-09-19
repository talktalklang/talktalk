//
//  InstantiatableType.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/19/24.
//
import OrderedCollections

public enum InstantiatableType: Hashable {
	case `struct`(StructType)
	case enumType(EnumType)
	case `protocol`(ProtocolType)

	public func apply(substitutions: OrderedDictionary<TypeVariable, InferenceType>, in context: InferenceContext) -> InferenceType {
		switch self {
		case .struct(let structType):
			structType.apply(substitutions: substitutions, in: context)
		case .enumType(let enumType):
			enumType.apply(substitutions: substitutions, in: context)
		case .protocol(let protocolType):
			protocolType.apply(substitutions: substitutions, in: context)
		}
	}

	public var context: InferenceContext {
		switch self {
		case .struct(let structType):
			structType.context
		case .enumType(let enumType):
			enumType.context
		case .protocol(let protocolType):
			protocolType.context
		}
	}

	public var typeContext: TypeContext {
		switch self {
		case .struct(let structType):
			structType.typeContext
		case .enumType(let enumType):
			enumType.typeContext
		case .protocol(let protocolType):
			protocolType.typeContext
		}
	}

	public func extract() -> any Instantiatable {
		switch self {
		case .struct(let structType):
			structType
		case .enumType(let enumType):
			enumType
		case .protocol(let protocolType):
			protocolType
		}
	}

	public func instantiate(with substitutions: OrderedDictionary<TypeVariable, InferenceType>, in context: InferenceContext) -> InstanceType {
		switch self {
		case .struct(let structType):
			structType.instantiate(with: substitutions, in: structType.context)
		case .enumType(let enumType):
			enumType.instantiate(with: substitutions, in: enumType.context)
		case .protocol(let protocolType):
			protocolType.instantiate(with: substitutions, in: protocolType.context)
		}
	}

	public func member(named name: String, in context: InferenceContext) -> InferenceResult? {
		switch self {
		case .struct(let structType):
			structType.member(named: name, in: context)
		case .enumType(let enumType):
			enumType.member(named: name, in: context)
		case .protocol(let protocolType):
			protocolType.member(named: name, in: context)
		}
	}

	public var name: String {
		switch self {
		case .struct(let structType):
			structType.name
		case .enumType(let enumType):
			enumType.name
		case .protocol(let protocolType):
			protocolType.name
		}
	}
}
