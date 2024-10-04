//
//  Enum.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 10/3/24.
//

import OrderedCollections

public final class Enum: MemberOwner, Instantiatable {
	public struct Case: Instantiatable, MemberOwner {
		public var typeParameters: [String : TypeVariable] { type.typeParameters }

		public let type: Enum
		public let name: String
		public let attachedTypes: [InferenceResult]

		public func staticMember(named name: String) -> InferenceResult? { nil }

		public func member(named name: String) -> InferenceResult? {
			let member = type.member(named: name)
			
			if case .type(.instance(.enumCase)) = member {
				return nil
			}

			return member
		}

		public func add(member: InferenceResult, named name: String, isStatic: Bool) throws {

		}

		public func instantiate(with substitutions: [TypeVariable : InferenceType]) -> Instance<Enum.Case> {
			Instance<Enum.Case>(type: self, substitutions: substitutions)
		}
	}

	public let name: String
	public var cases: OrderedDictionary<String, Case> = [:]
	public var members: [String: InferenceResult] = [:]
	public var staticMembers: [String: InferenceResult] = [:]
	public var typeParameters: [String: TypeVariable] = [:]

	init(name: String, cases: OrderedDictionary<String, Case>) {
		self.name = name
		self.cases = cases
	}

	static func extract(from type: InferenceType) -> Enum? {
		if case let .type(.enum(type)) = type {
			return type
		}

		return nil
	}

	public func instantiate(with substitutions: [TypeVariable : InferenceType]) -> Instance<Enum> {
		Instance<Enum>(type: self, substitutions: substitutions)
	}

	public func staticMember(named name: String) -> InferenceResult? {
		if let kase = cases[name] {
			let scheme = Scheme(name: name, variables: Array(typeParameters.values), type: .type(.enumCase(kase)))
			return .scheme(scheme)
		}

		return staticMembers[name]
	}

	public func member(named name: String) -> InferenceResult? {
		members[name]
	}

	public func add(member: InferenceResult, named name: String, isStatic: Bool) throws {
		members[name] = member
	}
}
