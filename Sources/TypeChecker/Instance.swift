//
//  Instance.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/15/24.
//

public protocol Instantiatable: Equatable, Hashable {
	var name: String { get }
	func member(named name: String, in context: InferenceContext) -> InferenceResult?
}

public class Instance<Kind: Instantiatable>: Equatable, Hashable, CustomStringConvertible {
	public static func == (lhs: Instance<Kind>, rhs: Instance<Kind>) -> Bool {
		lhs.type == rhs.type && lhs.substitutions == rhs.substitutions
	}

	let id: Int
	public let type: Kind
	var substitutions: [TypeVariable: InferenceType]

	public static func extract(from type: InferenceType) -> Instance<StructType>? {
		if case let .structInstance(instance) = type {
			return instance
		}

		return nil
	}

	public static func synthesized(_ type: Kind) -> Instance {
		Instance(id: -9999, type: type, substitutions: [:])
	}

	init(id: Int, type: Kind, substitutions: [TypeVariable: InferenceType]) {
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

	func member(named name: String, in context: InferenceContext) -> InferenceType? {
		guard let structMember = type.member(named: name, in: context) else {
			return nil
		}

		var instanceMember: InferenceType
		switch structMember {
		case let .scheme(scheme):
			// It's a method
			let type = context.instantiate(scheme: scheme)
			instanceMember = context.applySubstitutions(to: type, with: substitutions)
		case let .type(inferenceType):
			// It's a property
			instanceMember = context.applySubstitutions(to: inferenceType, with: substitutions)
		}

		return instanceMember
	}

	public var description: String {
		if substitutions.isEmpty {
			"\(type.name)()#\(id)"
		} else {
			"\(type.name)<\(substitutions.keys.map(\.description).joined(separator: ", "))>()#\(id)"
		}
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(type)
		hasher.combine(substitutions)
	}
}
