//
//  Enum.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 10/3/24.
//

import OrderedCollections

public final class Enum: MemberOwner, Instantiatable, CustomDebugStringConvertible {
	public struct Case: Instantiatable, MemberOwner, CustomDebugStringConvertible {
		public let type: Enum
		public let name: String
		public let module: String
		public let attachedTypes: [InferenceResult]

		public func staticMember(named name: String) -> InferenceResult? { nil }

		public func member(named name: String) -> InferenceResult? {
			let member = type.member(named: name)
			
			if case .resolved(.instance(.enumCase)) = member {
				return nil
			}

			return member
		}

		static func extract(from type: InferenceType) -> Enum.Case? {
			if case let .type(.enumCase(type)) = type {
				return type
			}

			return nil
		}

		public var members: [String: InferenceResult] {
			type.members
		}

		public var typeParameters: OrderedDictionary<String, TypeVariable> {
			get { type.typeParameters }
			set { }
		}

		public func add(member: InferenceResult, named name: String, isStatic: Bool) throws {
			()
		}

		public func instantiate(with substitutions: [TypeVariable : InferenceType]) -> Instance<Enum.Case> {
			Instance<Enum.Case>(type: self, substitutions: substitutions)
		}

		public var debugDescription: String {
			"\(type.name).\(name)(\(attachedTypes))"
		}
	}

	public let name: String
	public let module: String
	public var cases: OrderedDictionary<String, Case> = [:]
	public var members: [String: InferenceResult] = [:]
	public var staticMembers: [String: InferenceResult] = [:]
	public var typeParameters: OrderedDictionary<String, TypeVariable> = [:]

	init(name: String, module: String, cases: OrderedDictionary<String, Case>) {
		self.name = name
		self.module = module
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
		if let kase = cases[name] {
			let scheme = Scheme(name: name, variables: Array(typeParameters.values), type: .type(.enumCase(kase)))
			return .scheme(scheme)
		}

		return members[name]
	}

	public func add(member: InferenceResult, named name: String, isStatic: Bool) throws {
		members[name] = member
	}

	public var debugDescription: String {
		"enum \(name)"
	}
}
