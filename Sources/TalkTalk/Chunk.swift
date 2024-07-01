//
//  Chunk.swift
//  
//
//  Created by Pat Nakajima on 6/30/24.
//

struct Chunk: ~Copyable {
	var code = DynamicArray<Byte>()
	var constants = DynamicArray<Value>()
	var lines = DynamicArray<UInt32>()

	mutating func write(_ opcode: Opcode, line: UInt32) {
		write(opcode.rawValue, line: line)
	}

	mutating func write(_ byte: Byte, line: UInt32) {
		code.write(byte)
		lines.write(line)
	}

	mutating func write(value: Value, line: UInt32) {
		let offset = Byte(constants.write(value))
		write(offset, line: line)
	}

	func disassemble(_ name: String) {
		Disassembler(name: name, chunk: self).report()
	}
}
