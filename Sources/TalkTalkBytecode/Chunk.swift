//
//  Chunk.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/2/24.
//

public class Chunk {
	public var code: [Byte] = []
	public var constants: [Value] = []
	public var data: [Byte] = []
	public var lines: [UInt32] = []

	public init() {}

	public func disassemble() -> [Instruction] {
		var disassembler = Disassembler(chunk: self)
		return disassembler.disassemble()
	}

	public func finalize() -> StaticChunk {
		write(.return, line: 0)
		return StaticChunk(code: code, constants: constants)
	}

	public func emit(opcode: Opcode, line: UInt32) {
		write(byte: opcode.byte, line: line)
	}

	public func emit(constant value: Value, line: UInt32) {
		write(.constant, line: line)
		write(byte: write(constant: value), line: line)
	}

	// Emit static data for the program
	public func emit(data constantData: [Byte], line: UInt32) {
		let start = UInt64(data.count)
		data.append(contentsOf: constantData)
		emit(constant: .data(start), line: line)
	}

	private func write(constant value: Value) -> Byte {
		let idx = constants.count
		constants.append(value)
		return Byte(idx)
	}

	private func write(_ opcode: Opcode, line: UInt32) {
		write(byte: opcode.byte, line: line)
	}

	private func write(byte: Byte, line: UInt32) {
		code.append(byte)
		lines.append(line)
	}
}
