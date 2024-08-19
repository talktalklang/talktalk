//
//  Struct.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/8/24.
//

public struct Struct: Hashable, Equatable {
	public let name: String
	public let propertyCount: Int
	public var initializer: Int = 0
	public var methods: [StaticChunk] = []

	public init(name: String, propertyCount: Int) {
		self.name = name
		self.propertyCount = propertyCount
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(name)
	}
}
