//
//  StaticChunk.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/18/24.
//

public struct StaticChunk {
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
	private var subchunks: [StaticChunk] = []

	public init(chunk: Chunk) {
		self.init(
			code: chunk.code,
			lines: chunk.lines,
			constants: chunk.constants,
			data: chunk.data,
			arity: chunk.arity,
			localsCount: chunk.localsCount,
			upvalueCount: chunk.upvalueCount,
			subchunks: chunk.subchunks
		)
	}

	public init(code: [Byte], lines: [UInt32], constants: [Value], data: [StaticData], arity: Byte, localsCount: Byte, upvalueCount: Byte, subchunks: [Chunk]) {
		self.code = code
		self.constants = constants
		self.data = data
		self.arity = arity
		self.localsCount = localsCount
		self.upvalueCount = upvalueCount
		self.subchunks = subchunks.map {
			StaticChunk(
				code: $0.code,
				lines: $0.lines,
				constants: $0.constants,
				data: $0.data,
				arity: $0.arity,
				localsCount: $0.localsCount,
				upvalueCount: $0.upvalueCount,
				subchunks: $0.subchunks
			)
		}
	}
}
