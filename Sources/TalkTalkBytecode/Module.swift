//
//  Module.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/7/24.
//

public struct Module {
	// The name of the module. P straightforward.
	public let name: String

	// The list of chunks in this module
	public var chunks: [Chunk] = []

	// A list of symbols this module exports
	public var symbols: [Symbol] = []

	// A list of modules this module imports
	public var imports: [Module] = []

	public init(name: String) {
		self.name = name
	}

	public mutating func add(chunk: Chunk) {
		chunks.append(chunk)
	}
}
