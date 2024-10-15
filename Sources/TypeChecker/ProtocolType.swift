//
//  ProtocolType.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 10/5/24.
//

import OrderedCollections

public final class ProtocolType: MemberOwner, Instantiatable, Hashable, Equatable {
	public static func ==(lhs: ProtocolType, rhs: ProtocolType) -> Bool {
		lhs.name == rhs.name
	}

	public var typeParameters: OrderedDictionary<String, TypeVariable> = [:]
	public var members: [String: InferenceResult] = [:]

	public let name: String
	public let module: String

	init(name: String, module: String) {
		self.name = name
		self.module = module
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(name)
	}

	static func extract(from type: InferenceType) -> ProtocolType? {
		if case let .type(.protocol(type)) = type {
			return type
		}

		return nil
	}

	public func staticMember(named name: String) -> InferenceResult? { nil }

	public func instantiate(with substitutions: [TypeVariable : InferenceType]) -> Instance<ProtocolType> {
		Instance<ProtocolType>(type: self, substitutions: substitutions)
	}

	func missingConformanceRequirements<T: MemberOwner>(for type: T, in context: Context) -> Set<ConformanceRequirement> {
		var missingRequirements: Set<ConformanceRequirement> = []

		for requirement in requirements(in: context) {
			if !requirement.satisfied(by: type, in: context) {
				missingRequirements.insert(requirement)
			}
		}

		return missingRequirements
	}

	public func member(named name: String) -> InferenceResult? {
		members[name]
	}

	public func add(member: InferenceResult, named name: String, isStatic: Bool) throws {
		members[name] = member
	}

	public var debugDescription: String {
		"Protocol \(name)"
	}

	func requirements(in context: Context) -> [ConformanceRequirement] {
		members.map {
			ConformanceRequirement(name: $0.key, type: $0.value)
		}
	}
}
