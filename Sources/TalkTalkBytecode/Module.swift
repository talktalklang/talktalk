//
//  Module.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/7/24.
//

import OrderedCollections

public struct EnumCase: Equatable {
	// The name of this case. All cases have names even if they don't have
	// associated values.
	public let name: String

	// Associated values for the enum
	public let values: [Value]
}

public struct Enum: Equatable, Sendable, Codable, Hashable {
	// What is this enum named
	public let name: String

	// What are the cases of this enum
	public let cases: [String]

	public init(name: String, cases: [String]) {
		self.name = name
		self.cases = cases
	}
}

public struct Module: Equatable, @unchecked Sendable {
	// The name of the module. P straightforward.
	public let name: String

	// For executable modules, this is the entry chunk to be run
	public var main: StaticChunk?

	// The list of chunks in this module
	public var chunks: [Symbol: StaticChunk] = [:]

	// The list of top level structs in this module
	public var structs: [Symbol: Struct] = [:]

	// The list of top level enums in this module
	public var enums: [Enum] = []

	// A list of symbols this module exports
	public var symbols: OrderedDictionary<Symbol, SymbolInfo>

	// A list of modules this module imports
	public var imports: [Module] = []

	// If a global value hasn't been used yet, its initializer goes into
	// here so it can be initialized lazily
	public var valueInitializers: [Symbol: StaticChunk] = [:]

	public init(name: String, main: StaticChunk? = nil, symbols: OrderedDictionary<Symbol, SymbolInfo>) {
		self.name = name
		self.main = main
		self.symbols = symbols
	}

	public mutating func add(chunk: StaticChunk) {
		chunks[chunk.symbol] = chunk
	}
}
