//
//  ProtocolType.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/18/24.
//

import OrderedCollections

public struct ProtocolTypeV1: Equatable, Hashable, InstantiatableV1 {
	public static func == (lhs: Self, rhs: Self) -> Bool {
		lhs.name == rhs.name && lhs.typeContext.properties == rhs.typeContext.properties
	}

	public let name: String
	public let context: InferenceContext
	public let typeContext: TypeContext
	public var conformances: [ProtocolTypeV1] { typeContext.conformances }

	public func hash(into hasher: inout Hasher) {
		hasher.combine(name)
		hasher.combine(typeContext.properties)
		hasher.combine(typeContext.methods)
	}

	public func missingConformanceRequirements(for type: any InstantiatableV1, in context: InferenceContext) -> Set<ConformanceRequirementV1> {
		var missingRequirements: Set<ConformanceRequirementV1> = []

		for requirement in requirements(in: context) {
			if !requirement.satisfied(by: type, in: context) {
				missingRequirements.insert(requirement)
			}
		}

		return missingRequirements
	}

	public func apply(substitutions _: OrderedDictionary<TypeVariable, InferenceType>, in _: InferenceContext) -> InferenceType {
		.instantiatable(.protocol(self))
	}

	public func requirements(in _: InferenceContext) -> Set<ConformanceRequirementV1> {
		var result: Set<ConformanceRequirementV1> = []

		for (name, type) in typeContext.methods {
			result.insert(.init(name: name, type: type))
		}

		for (name, type) in typeContext.properties {
			result.insert(.init(name: name, type: type))
		}

		return result
	}

	public static func extract(from type: InferenceType) -> ProtocolTypeV1? {
		if case let .instantiatable(.protocol(type)) = type {
			return type
		}

		return nil
	}

	public func member(named name: String, in _: InferenceContext) -> InferenceResult? {
		if let member = properties[name] ?? methods[name] {
//			return .type(context.applySubstitutions(to: member.asType(in: context)))
			return member
		}

		if let typeParam = typeContext.typeParameters.first(where: { $0.name == name }) {
			return .resolved(.typeVar(typeParam))
		}

		return nil
	}

	func method(named name: String, in context: InferenceContext) -> InferenceResult? {
		if let member = methods[name] {
			return .resolved(context.applySubstitutions(to: member.asType(in: context)))
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