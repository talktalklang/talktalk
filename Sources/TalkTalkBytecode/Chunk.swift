//
//  Chunk.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/2/24.
//

// A Chunk represents a basic unit of code for a function. Function definitions
// each have a chunk.
public class Chunk {
	// The main code that the VM runs. It's a mix of opcodes and opcode operands
	public var code: [Byte] = []

	// Constant values emitted from literals found in the source
	public var constants: [Value] = []

	// Larger blobs of data like strings from literals found in the source
	public var data: [Byte] = []

	// Tracks the code array so we can output line numbers when disassambling
	public var lines: [UInt32] = []

	// How many arguments should this chunk expect
	public var arity: Byte = 0
	public var depth: Byte = 0
	public var parent: Chunk?
	public var subchunks: [Chunk] = []

	// Tracks local variable slots
	public var localsTable: [String: Byte] = [:]

	public init() {}

	public init(parent: Chunk, arity: Byte, depth: Byte) {
		self.parent = parent
		self.arity = arity
		self.depth = depth
	}

	public func disassemble() -> [Instruction] {
		var disassembler = Disassembler(chunk: self)
		return disassembler.disassemble()
	}

	public func dump() {
		print(disassemble().map(\.description).joined(separator: "\n"))
	}

	public func finalize() -> Chunk {
		write(.return, line: 0)
		return self
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

	public func emitClosure(subchunkID: Byte, name: String?, arity: Byte, upvalueCount: Byte, line: UInt32) {
		// Emit the opcode to define a closure
		write(.defClosure, line: line)
		write(byte: subchunkID, line: line)
	}

	public func emit(opcode: Opcode, local name: String, line: UInt32) {
		let local = localsTable[name, default: Byte(localsTable.count)]
		localsTable[name] = local

		write(opcode, line: line)
		write(byte: local, line: line)
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
