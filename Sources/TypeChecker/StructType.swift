//
//  StructType.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 10/2/24.
//

public final class StructType: MemberOwner, Instantiatable, Equatable {
	public let name: String
	public var members: [String: InferenceResult]
	public var staticMembers: [String: InferenceResult]
	public var typeParameters: [String: TypeVariable] = [:]

	public static func ==(lhs: StructType, rhs: StructType) -> Bool {
		(lhs.name, lhs.members) == (rhs.name, rhs.members)
	}

	init(name: String, members: [String : InferenceResult] = [:], staticMembers: [String: InferenceResult] = [:]) {
		self.name = name
		self.members = members
		self.staticMembers = staticMembers
	}

	static func extract(from type: InferenceType) -> StructType? {
		guard case let .struct(type) = type else {
			return nil
		}

		return type
	}

	public func instantiate(with substitutions: [TypeVariable: InferenceResult]) -> Instance<StructType> {
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
