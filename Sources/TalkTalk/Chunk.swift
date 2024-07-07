//
//  Chunk.swift
//
//
//  Created by Pat Nakajima on 6/30/24.
//

public struct Chunk: Hashable {
	public static func == (lhs: Chunk, rhs: Chunk) -> Bool {
		lhs.hashValue == rhs.hashValue
	}

	var code = DynamicArray<Byte>()
	var constants = DynamicArray<Value>()
	var lines = DynamicArray<Int>()

	public func hash(into hasher: inout Swift.Hasher) {
		hasher.combine(code.hashValue)
		hasher.combine(constants.hashValue)
		hasher.combine(lines.hashValue)
	}

	var count: Int {
		code.count
	}

	mutating func make(constant value: Value) -> Byte {
		Byte(constants.write(value))
	}

	mutating func write(_ opcode: Opcode, line: Int) {
		write(opcode.byte, line: line)
	}

	mutating func write(_ byte: Byte, line: Int) {
		code.write(byte)
		lines.write(line)
	}

	mutating func write(value: consuming Value, line: Int) {
		write(.constant, line: line)
		let offset = Byte(constants.write(value))
		write(offset, line: line)
	}

	func disassemble<Output: OutputCollector>(to output: inout Output) {
		Disassembler.dump(chunk: self, into: &output)
	}
}
