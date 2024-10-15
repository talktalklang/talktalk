//
//  StructType.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 10/2/24.
//

import OrderedCollections

public final class StructType: MemberOwner, Instantiatable, Equatable, CustomDebugStringConvertible {
	public let name: String
	public let module: String
	public var members: [String: InferenceResult]
	public var staticMembers: [String: InferenceResult]
	public var typeParameters: OrderedDictionary<String, TypeVariable> = [:]

	public static func ==(lhs: StructType, rhs: StructType) -> Bool {
		(lhs.name, lhs.members) == (rhs.name, rhs.members)
	}

	init(name: String, module: String, members: [String : InferenceResult] = [:], staticMembers: [String: InferenceResult] = [:]) {
		self.name = name
		self.module = module
		self.members = members
		self.staticMembers = staticMembers
	}

	public static func extract(from type: InferenceType) -> StructType? {
		if case let .type(.struct(type)) = type {
			return type
		}

		if case let .self(type as StructType) = type {
			return type
		}

		return nil
	}

	public var debugDescription: String {
		"struct \(name)"
	}

	public func instantiate(with substitutions: [TypeVariable: InferenceType]) -> Instance<StructType> {
		Instance(type: self, substitutions: substitutions)
	}

	public func add(member: InferenceResult, named name: String, isStatic: Bool) throws {
		if isStatic {
			staticMembers[name] = member
		} else {
			members[name] = member
		}
	}

	public func staticMember(named name: String) -> InferenceResult? {
		staticMembers[name]
	}

	public func member(named name: String) -> InferenceResult? {
		members[name]
	}
}
