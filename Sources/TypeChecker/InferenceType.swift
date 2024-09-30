//
//  Type.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/25/24.
//
import Foundation
import OrderedCollections

public indirect enum InferenceType {
	public static func optional(_ type: InferenceType) -> InferenceType {
		let enumType = EnumType.extract(from: .type(Inferencer.stdlib.type(named: "Optional")!))!
		let wrapped = enumType.typeContext.typeParameters.first!
		let instance = enumType.instantiate(with: [wrapped: type], in: .init(moduleName: "Standard", parent: nil, environment: .init(), constraints: .init()))
		return .instance(instance)
	}

	// Something we'll fill in later.
	case typeVar(TypeVariable)

	// Primitives, like int or string
	case base(Primitive)

	// Function type. Also used for methods. The first type is args, the second is return type.
	case function([InferenceResult], InferenceResult)

	// Instances
	case instance(InstanceType)

	// Struct stuff
	case instantiatable(InstantiatableType)

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

	// Enum types
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
}
