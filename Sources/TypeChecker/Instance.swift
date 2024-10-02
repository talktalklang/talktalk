//
//  Instance.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 10/2/24.
//

public protocol Instance: MemberOwner {
	associatedtype Kind: Instantiatable

	var type: Kind { get }
	var substitutions: [TypeVariable: InferenceResult] { get }
}

public struct StructInstance: Instance, MemberOwner {
	public var name: String { type.name }

	public let type: StructType
	public let substitutions: [TypeVariable: InferenceResult]

	public func member(named name: String) -> InferenceResult? {
		type.member(named: name)
	}

	public func add(member: InferenceResult, named name: String) throws {

	}
}

public extension Instance where Self == StructInstance {
	static func extract(from type: InferenceType) -> StructInstance? {
		guard case let .instance(instance as StructInstance) = type else {
			return nil
		}

		return instance
	}

	static func `struct`(_ structType: StructType, substitutions: [TypeVariable: InferenceResult]) -> StructInstance {
		StructInstance(type: structType, substitutions: substitutions)
	}
}
