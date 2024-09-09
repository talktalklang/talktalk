//
//  Capture.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/8/24.
//

public struct Capture: Codable, Sendable, Equatable, Hashable {
	public enum Location: Codable, Sendable, Equatable, Hashable {
		case stack(Int), heap(Heap.Pointer)
	}

	public let name: String
	public let symbol: Symbol
	public let location: Location

	public init(name: String, symbol: Symbol, location: Location) {
		self.name = name
		self.symbol = symbol
		self.location = location
	}
}
