//
//  Type.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/25/24.
//
import Foundation
import OrderedCollections

public enum TypeWrapper {
	case `struct`(StructType), `enum`(Enum), enumCase(Enum.Case)

	func staticMember(named name: String) -> InferenceResult? {
		switch self {
		case .struct(let structType):
			structType.staticMember(named: name)
		case .enum(let enumType):
			enumType.staticMember(named: name)
		case .enumCase(let enumCase):
			enumCase.staticMember(named: name)
		}
	}
}

public indirect enum InferenceType {
	public static func optional(_ type: InferenceType) -> InferenceType {
		let enumType = EnumTypeV1.extract(from: .type(Inferencer.stdlib.type(named: "Optional")!))!
		let wrapped = enumType.typeContext.typeParameters.first!
		let instance = enumType.instantiate(with: [wrapped: type], in: .init(moduleName: "Standard", parent: nil, environment: .init(), constraints: .init()))
		return .instanceV1(instance)
	}

	// Something we'll fill in later.
	case typeVar(TypeVariable)

	// Primitives, like int or string
	case base(Primitive)

	// self?
	case `self`(any MemberOwner)

	// Instances
	case instance(InstanceWrapper)

	// Structs
	case type(TypeWrapper)

	// Function type. Also used for methods. The first type is args, the second is return type.
	case function([InferenceResult], InferenceResult)

	// When we expect a type but can't establish one yet
	case placeholder(TypeVariable)

	// When we expect an instance of a type but can't establish one yet
	case instancePlaceholder(TypeVariable)

	// Errors
	case error(InferenceError)

	// Used for Type expressions that refer to actual types
	case kind(InferenceType)

	// Used for `self` in types that support it
	case selfVar(InferenceType)

	// Pattern matching (type, associated values)
	case pattern(Pattern)

	// When we can't figure it out or don't care
	case any

	// The absence of a type
	case void

	// Instances (Deprecated)
	@available(*, deprecated, message: "I think we don't want this anymore.")
	case instanceV1(InstanceType)

	// Struct stuff
	@available(*, deprecated, message: "I think we don't want this anymore.")
	case instantiatable(InstantiatableType)

	// Enum types
	@available(*, deprecated, message: "I think we don't want this anymore.")
	case enumCaseV1(EnumCase)

	static func typeVar(_ name: String, _ id: VariableID, isGeneric: Bool = false) -> InferenceType {
		InferenceType.typeVar(TypeVariable(name, id, isGeneric))
	}
}
