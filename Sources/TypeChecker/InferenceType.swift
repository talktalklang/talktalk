//
//  Type.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/25/24.
//
import Foundation
import TalkTalkCore
import OrderedCollections

public indirect enum InferenceType {
	public static func optional(_ type: InferenceType) -> InferenceType {
		let optionalType = Library.standard.files.first(where: { $0.path.contains("Optional.talk") })!
		let context = try! ContextVisitor.visit(Parser.parse(optionalType), module: "Standard")

		let enumType = Enum.extract(from: context.type(named: "Optional")!.instantiate(in: context).type)!
		let wrapped = enumType.typeParameters["Wrapped"]!
		let instance = enumType.instantiate(with: [wrapped: type])

		return .instance(.enum(instance))
	}

	func asInstance(with substitutions: [TypeVariable: InferenceType]) -> InferenceType {
		if case let .type(type) = self {
			return .instance(type.instantiate(with: substitutions))
		} else {
			return self
		}
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

	// Pattern matching
	case pattern(Pattern)

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

	// When we can't figure it out or don't care
	case any

	// The absence of a type
	case void

	static func typeVar(_ name: String, _ id: VariableID, isGeneric: Bool = false) -> InferenceType {
		InferenceType.typeVar(TypeVariable(name, id, isGeneric))
	}
}
