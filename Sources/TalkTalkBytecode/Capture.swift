//
//  Capture.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/8/24.
//

public struct Capture: Codable, Sendable, Equatable {
	public let name: String
	public let symbol: Symbol
	public let depth: Int

	public init(name: String, symbol: Symbol, depth: Int) {
		self.name = name
		self.symbol = symbol
		self.depth = depth
	}
}
