//
//  Instance.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 10/2/24.
//

public protocol Instance {
	associatedtype Kind: Instantiatable

	var type: Kind { get }
}

public struct StructInstance: Instance {
	public let type: StructType
}

public extension Instance where Self == StructInstance {
	static func extract(from type: InferenceType) -> StructInstance? {
		guard case let .instance(instance as StructInstance) = type else {
			return nil
		}

		return instance
	}

	static func `struct`(_ structType: StructType) -> StructInstance {
		StructInstance(type: structType)
	}
}
