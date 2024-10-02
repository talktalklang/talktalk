//
//  StructType.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 10/2/24.
//

public protocol MemberOwner {
	var name: String { get }

	func member(named name: String) -> InferenceResult?
	func add(member: InferenceResult, named name: String) throws
}

public class StructType: MemberOwner, Instantiatable {
	public let name: String
	public var members: [String: InferenceResult]

	init(name: String, members: [String : InferenceResult] = [:]) {
		self.name = name
		self.members = members
	}

	static func extract(from type: InferenceType) -> StructType? {
		guard case let .struct(type) = type else {
			return nil
		}

		return type
	}

	public func instantiate(with substitutions: [TypeVariable: InferenceResult]) -> any Instance {
		StructInstance.struct(self, substitutions: substitutions)
	}

	public func add(member: InferenceResult, named name: String) throws {
		members[name] = member
	}

	public func member(named name: String) -> InferenceResult? {
		members[name]
	}
}
