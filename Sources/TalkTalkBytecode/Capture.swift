//
//  Capture.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/8/24.
//

public struct Capture: Codable, Sendable, Equatable, Hashable {
	public enum Location: Codable, Sendable, Equatable, Hashable {
		case stack(Int), heap(Int, Int)
	}

	public let symbol: StaticSymbol
	public let location: Location

	public init(symbol: StaticSymbol, location: Location) {
		self.symbol = symbol
		self.location = location
	}
}
