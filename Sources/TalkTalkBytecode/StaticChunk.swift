//
//  StaticChunk.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/18/24.
//

public final class StaticChunk: Equatable, Codable, Sendable {
	public static func == (lhs: StaticChunk, rhs: StaticChunk) -> Bool {
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

	// Which of this chunk's locals are captured by a child fn.
	public let capturedLocals: Set<StaticSymbol>

	// Which of this chunk's locals are captured from a parent
	public let capturing: Set<Capture>

	// Debug info
	let debugInfo: DebugInfo

	struct DebugInfo: Equatable, Codable {
		public var name: String
		public var lines: [UInt32]
		public var debugLogs: [String]
		public var locals: [StaticSymbol]
		public var depth: Byte
		public var path: String
	}

	public init(chunk: Chunk) {
		self.code = chunk.code
		self.symbol = chunk.symbol
		self.constants = chunk.constants
		self.data = chunk.data
		self.arity = chunk.arity
		self.capturedLocals = chunk.capturedLocals
		self.capturing = chunk.captures
		self.debugInfo = DebugInfo(
			name: chunk.name,
			lines: chunk.lines,
			debugLogs: chunk.debugLogs,
			locals: chunk.locals,
			depth: chunk.depth,
			path: chunk.path
		)
	}

	public var name: String {
		debugInfo.name
	}
}
