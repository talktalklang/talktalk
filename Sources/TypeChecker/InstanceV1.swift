//
//  Instance.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/15/24.
//

import OrderedCollections

public protocol InstantiatableV1: Equatable, Hashable {
	var name: String { get }
	var context: InferenceContext { get }
	var typeContext: TypeContext { get }
	var conformances: [ProtocolTypeV1] { get }
	func member(named name: String, in context: InferenceContext) -> InferenceResult?
	func apply(substitutions: OrderedDictionary<TypeVariable, InferenceType>, in context: InferenceContext) -> InferenceType
}

public extension InstantiatableV1 {
	func instantiate(with substitutions: OrderedDictionary<TypeVariable, InferenceType>, in context: InferenceContext) -> InstanceType {
		let instance = InstanceV1(
			id: context.nextIdentifier(named: name),
			type: self,
			substitutions: typeContext.typeParameters.reduce(into: [:]) {
				if let sub = substitutions[$1] {
					$0[$1] = sub
				} else if context.substitutions[$1] != nil {
					$0[$1] = context.applySubstitutions(to: .typeVar($1))
				} else {
					$0[$1] = .typeVar(context.freshTypeVariable($1.description, file: #file, line: #line))
				}
			}
		)

		context.log("Instantiated \(instance), \(instance.substitutions)", prefix: "() ")

		// swiftlint:disable force_cast fatal_error
		return switch self {
		case is StructTypeV1:
			.struct(instance as! InstanceV1<StructTypeV1>)
		case is EnumTypeV1:
			.enumType(instance as! InstanceV1<EnumTypeV1>)
		case is ProtocolTypeV1:
			.protocol(instance as! InstanceV1<ProtocolTypeV1>)
		default:
			fatalError("Unhandled type: \(self)")
		}
		// swiftlint:enable force_cast fatal_error
	}

	func staticMember(named name: String) -> InferenceResult? {
		typeContext.staticMethods[name] ?? typeContext.staticProperties[name]
	}

	var typeParameters: [TypeVariable] {
		typeContext.typeParameters
	}

	var methods: OrderedDictionary<String, InferenceResult> {
		typeContext.methods
	}

	var properties: OrderedDictionary<String, InferenceResult> {
		typeContext.properties
	}
}

public class InstanceV1<T: InstantiatableV1>: Equatable, Hashable, CustomStringConvertible, CustomDebugStringConvertible {
	public static func == (lhs: InstanceV1, rhs: InstanceV1) -> Bool {
		lhs.type.hashValue == rhs.type.hashValue && lhs.substitutions == rhs.substitutions
	}

	let id: Int
	public let type: T
	var substitutions: OrderedDictionary<TypeVariable, InferenceType>

	public static func extract(from type: InferenceType) -> InstanceV1<T>? {
		guard case let .instanceV1(instance) = type else {
			return nil
		}

		return instance.extract(T.self)
	}

	public static func synthesized(_ type: T) -> InstanceV1 {
		InstanceV1(id: -9999, type: type, substitutions: [:])
	}

	init(id: Int, type: T, substitutions: OrderedDictionary<TypeVariable, InferenceType>) {
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

	public func member(named name: String, in context: InferenceContext) -> InferenceType? {
		guard let structMember = type.member(named: name, in: context) else {
			return nil
		}

		var instanceMember: InferenceType
		switch structMember {
		case let .scheme(scheme):
			// It's a method
			let type = context.instantiate(scheme: scheme)
			instanceMember = context.applySubstitutions(to: type, with: substitutions)
		case let .resolved(inferenceType):
			// It's a property
			instanceMember = context.applySubstitutions(to: inferenceType, with: substitutions)
		}

		return instanceMember
	}

	public var debugDescription: String {
		if substitutions.isEmpty {
			"\(type.name)()#\(id)"
		} else {
			"\(type.name)<\(substitutions.keys.map(\.debugDescription).joined(separator: ", "))>()#\(id)"
		}
	}

	public var description: String {
		if substitutions.isEmpty {
			"\(type.name)()#\(id)"
		} else {
			"\(type.name)<\(substitutions.keys.map(\.description).joined(separator: ", "))>()#\(id)"
		}
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(type.hashValue)
		hasher.combine(substitutions)
	}
}
