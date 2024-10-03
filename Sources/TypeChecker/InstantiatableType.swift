//
//  InstantiatableType.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/19/24.
//
import OrderedCollections

public enum InstantiatableType: Hashable {
	case `struct`(StructTypeV1)
	case enumType(EnumTypeV1)
	case `protocol`(ProtocolType)

	public func apply(substitutions: OrderedDictionary<TypeVariable, InferenceType>, in context: InferenceContext) -> InferenceType {
		switch self {
		case let .struct(structType):
			structType.apply(substitutions: substitutions, in: context)
		case let .enumType(enumType):
			enumType.apply(substitutions: substitutions, in: context)
		case let .protocol(protocolType):
			protocolType.apply(substitutions: substitutions, in: context)
		}
	}

	public var context: InferenceContext {
		switch self {
		case let .struct(structType):
			structType.context
		case let .enumType(enumType):
			enumType.context
		case let .protocol(protocolType):
			protocolType.context
		}
	}

	public var typeContext: TypeContext {
		switch self {
		case let .struct(structType):
			structType.typeContext
		case let .enumType(enumType):
			enumType.typeContext
		case let .protocol(protocolType):
			protocolType.typeContext
		}
	}

	public func extract() -> any InstantiatableV1 {
		switch self {
		case let .struct(structType):
			structType
		case let .enumType(enumType):
			enumType
		case let .protocol(protocolType):
			protocolType
		}
	}

	public func instantiate(with substitutions: OrderedDictionary<TypeVariable, InferenceType>, in _: InferenceContext) -> InstanceType {
		switch self {
		case let .struct(structType):
			structType.instantiate(with: substitutions, in: structType.context)
		case let .enumType(enumType):
			enumType.instantiate(with: substitutions, in: enumType.context)
		case let .protocol(protocolType):
			protocolType.instantiate(with: substitutions, in: protocolType.context)
		}
	}

	public func staticMember(named name: String, in _: InferenceContext) -> InferenceResult? {
		switch self {
		case let .struct(structType):
			structType.staticMember(named: name)
		case let .enumType(enumType):
			enumType.staticMember(named: name)
		case let .protocol(protocolType):
			protocolType.staticMember(named: name)
		}
	}

	public func member(named name: String, in context: InferenceContext) -> InferenceResult? {
		switch self {
		case let .struct(structType):
			structType.member(named: name, in: context)
		case let .enumType(enumType):
			enumType.member(named: name, in: context)
		case let .protocol(protocolType):
			protocolType.member(named: name, in: context)
		}
	}

	public var name: String {
		switch self {
		case let .struct(structType):
			structType.name
		case let .enumType(enumType):
			enumType.name
		case let .protocol(protocolType):
			protocolType.name
		}
	}
}
