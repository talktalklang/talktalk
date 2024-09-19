//
//  Type.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/25/24.
//
import Foundation
import OrderedCollections

public indirect enum InferenceType {
	// Something we'll fill in later.
	case typeVar(TypeVariable)

	// Primitives, like int or string
	case base(Primitive)

	// Function type. Also used for methods. The first type is args, the second is return type.
	case function([InferenceType], InferenceType)

	// Instances
	case instance(InstanceType)

	// Struct stuff
	case instantiatable(any Instantiatable)

	// When we expect a type but can't establish one yet
	case placeholder(TypeVariable)

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
