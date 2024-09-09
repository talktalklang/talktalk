//
//  StaticChunk.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/18/24.
//

public final class StaticChunk: Equatable, Codable, Sendable {
	public static func ==(lhs: StaticChunk, rhs: StaticChunk) -> Bool {
		lhs.code == rhs.code
	}

	public let symbol: Symbol

	// The main code that the VM runs. It's a mix of opcodes and opcode operands
	public let code: ContiguousArray<Code>

	// Constant values emitted from literals found in the source
	public let constants: [Value]

	// Larger blobs of data like strings from literals found in the source
	public let data: [StaticData]

	// How many arguments should this chunk expect
	public let arity: Byte

	// How many locals does this chunk worry about? We start at 1 to reserve 0
	// for things like `self`.
	public let localsCount: Byte

	// How many upvalues does this chunk refer to
	public let upvalueCount: Byte

	// Debug info
	internal let debugInfo: DebugInfo

	struct DebugInfo: Equatable, Codable {
		public var name: String
		public var lines: [UInt32]
		public var locals: [Symbol]
		public var upvalueNames: [String]
		public var depth: Byte
		public var path: String
	}

	public init(chunk: Chunk) {
		self.code = chunk.code
		self.symbol = chunk.symbol
		self.constants = chunk.constants
		self.data = chunk.data
		self.arity = chunk.arity
		self.localsCount = chunk.localsCount
		self.upvalueCount = chunk.upvalueCount
		self.debugInfo = DebugInfo(
			name: chunk.name,
			lines: chunk.lines,
			locals: chunk.locals,
			upvalueNames: chunk.upvalueNames,
			depth: chunk.depth,
			path: chunk.path
		)
	}

	public var name: String {
		debugInfo.name
	}
}
