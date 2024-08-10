//
//  Module.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/7/24.
//

public struct Module: Equatable, @unchecked Sendable {
	// The name of the module. P straightforward.
	public let name: String

	public var main: Chunk?

	// The list of chunks in this module
	public var chunks: [Chunk] = []

	// The list of top level structs in this module
	public var structs: [Struct] = []

	// A list of symbols this module exports
	public var symbols: [Symbol: Int]

	// A list of modules this module imports
	public var imports: [Module] = []

	// If a global value hasn't been used yet, its initializer goes into
	// here so it can be initialized lazily
	public var valueInitializers: [Byte: Chunk] = [:]

	// Lists of global values used during execution
	public var values: [Byte: Value] = [:]
	public var functions: [Byte: Value] = [:]

	public init(name: String, main: Chunk? = nil, symbols: [Symbol: Int]) {
		self.name = name
		self.main = main
		self.symbols = symbols
	}

	public mutating func add(chunk: Chunk) {
		chunks.append(chunk)
	}
}
