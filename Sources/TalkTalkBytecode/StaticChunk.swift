//
//  StaticChunk.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/2/24.
//

public struct StaticChunk {
	public let code: [Byte]
	public let constants: [Value]
	public let data: [Byte]
	public let lines: [UInt32]

	public init(
		code: [Byte],
		constants: [Value],
		data: [Byte],
		lines: [UInt32]
	) {
		self.code = code
		self.constants = constants
		self.data = data
		self.lines = lines
	}

	internal init(_ chunk: Chunk) {
		self.code = chunk.code
		self.constants = chunk.constants
		self.data = chunk.data
		self.lines = chunk.lines
	}

	public func disassemble() -> [Instruction] {
		var disassembler = Disassembler(chunk: self)
		return disassembler.disassemble()
	}

	public func dump() {
		print(disassemble().map(\.description).joined(separator: "\n"))
	}
}
