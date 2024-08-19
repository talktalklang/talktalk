//
//  StaticChunk.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/18/24.
//

public struct StaticChunk: Equatable, Codable {
	// The main code that the VM runs. It's a mix of opcodes and opcode operands
	public var code: [Byte] = []

	// Constant values emitted from literals found in the source
	public var constants: [Value] = []

	// Larger blobs of data like strings from literals found in the source
	public var data: [StaticData] = []

	// How many arguments should this chunk expect
	public var arity: Byte = 0

	// How many locals does this chunk worry about? We start at 1 to reserve 0
	// for things like `self`.
	public var localsCount: Byte = 1

	// How many upvalues does this chunk refer to
	public var upvalueCount: Byte = 0

	// Other callable chunks
	public var subchunks: [StaticChunk] = []

	// Debug info
	internal var debugInfo: DebugInfo

	struct DebugInfo: Equatable, Codable {
		public var name: String
		public var lines: [UInt32]
		public var localNames: [String]
		public var upvalueNames: [String]
		public var depth: Byte
	}

	public init(chunk: Chunk) {
		self.code = chunk.code
		self.constants = chunk.constants
		self.data = chunk.data
		self.arity = chunk.arity
		self.localsCount = chunk.localsCount
		self.upvalueCount = chunk.upvalueCount
		self.debugInfo = DebugInfo(
			name: chunk.name,
			lines: chunk.lines,
			localNames: chunk.localNames,
			upvalueNames: chunk.upvalueNames,
			depth: chunk.depth
		)
	}

	public var name: String {
		debugInfo.name
	}
}
