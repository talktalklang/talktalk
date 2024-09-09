//
//  Module.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/7/24.
//

public struct Module: Equatable, @unchecked Sendable {
	// The name of the module. P straightforward.
	public let name: String

	public var main: StaticChunk?

	// The list of chunks in this module
	public var chunks: [Symbol: StaticChunk] = [:]

	// The list of top level structs in this module
	public var structs: [Symbol: Struct] = [:]

	// A list of symbols this module exports
	public var symbols: [Symbol: SymbolInfo]

	// A list of modules this module imports
	public var imports: [Module] = []

	// If a global value hasn't been used yet, its initializer goes into
	// here so it can be initialized lazily
	public var valueInitializers: [Symbol: StaticChunk] = [:]

	public init(name: String, main: StaticChunk? = nil, symbols: [Symbol: SymbolInfo]) {
		self.name = name
		self.main = main
		self.symbols = symbols
	}

	public mutating func add(chunk: StaticChunk) {
		chunks[chunk.symbol] = chunk
	}
}
