//
//  ProtocolType.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 10/5/24.
//

import OrderedCollections

public final class ProtocolType: MemberOwner, Instantiatable {
	public var typeParameters: OrderedDictionary<String, TypeVariable> = [:]
	public var members: [String: InferenceResult] = [:]

	public let name: String

	init(name: String) {
		self.name = name
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
