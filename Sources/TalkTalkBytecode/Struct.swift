//
//  Struct.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/8/24.
//

public struct Struct: Equatable, Hashable, Codable, Sendable {
	public let name: String
	public let propertyCount: Int
	public var initializer: StaticSymbol?
	public var methods: [StaticChunk] = []

	public init(name: String, propertyCount: Int) {
		self.name = name
		self.propertyCount = propertyCount
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(name)
	}
}
