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

	internal init(staticChunk: StaticChunk) {
		self.code = staticChunk.code
		self.constants = staticChunk.constants
		self.data = staticChunk.data
		self.lines = staticChunk.lines
	}

	public func disassemble() -> [Instruction] {
		return StaticChunk(self).disassemble()
	}

	public func dump() {
		StaticChunk(self).dump()
	}

	public func finalize() -> StaticChunk {
		write(.return, line: 0)
		return StaticChunk(code: code, constants: constants, data: data, lines: lines)
	}

	public func emit(jump opcode: Opcode, line: UInt32) -> Int {
		// Write the jump instruction first
		write(opcode, line: line)

		// Use two bytes for the offset, which lets us jump over 65k bytes of code.
		// We'll fill these in with patchJump later.
		write(.jumpPlaceholder, line: line)
		write(.jumpPlaceholder, line: line)

		// Return the current location of our chunk code, offset by 2 (since that's
		// where we're gonna store our offset.
		return code.count - 2
	}

	public func patchJump(_ offset: Int) throws {
		// -2 to adjust for the bytecode for the jump offset itself
		let jump = code.count - offset - 2
		if jump > UInt16.max {
			throw BytecodeError.jumpSizeTooLarge
		}

		// Go back and replace the two placeholder bytes from emit(jump:)
		// the actual offset to jump over.
		let (a, b) = uint16ToBytes(jump)
		code[offset] = a
		code[offset + 1] = b
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

	private func uint16ToBytes(_ uint16: Int) -> (Byte, Byte) {
		let a = (uint16 >> 8) & 0xFF
		let b = (uint16 & 0xFF)

		return (Byte(a), Byte(b))
	}
}
