//
//  Module.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/7/24.
//

public struct Module {
	// The name of the module. P straightforward.
	public let name: String

	public var main: Chunk

	// The list of chunks in this module
	public var chunks: [Chunk] = []

	// A list of symbols this module exports
	public var symbols: [Symbol] = []

	// A list of modules this module imports
	public var imports: [Module] = []

	// A list of globals used during execution
	public var globals: [Byte: Value] = [:]

	// A helper for when we just want to run a chunk
	public static func main(_ chunk: Chunk) -> Module {
		Module(name: "main", main: chunk)
	}

	public init(name: String, main: Chunk) {
		self.name = name
		self.main = main
	}

	public mutating func add(chunk: Chunk) {
		chunks.append(chunk)
	}
}
