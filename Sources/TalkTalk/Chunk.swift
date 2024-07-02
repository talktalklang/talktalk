//
//  Chunk.swift
//  
//
//  Created by Pat Nakajima on 6/30/24.
//

public class Chunk {
	var code = DynamicArray<Byte>()
	var constants = DynamicArray<Value>()
	var lines = DynamicArray<Int>()

	func write(_ opcode: Opcode, line: Int) {
		write(opcode.rawValue, line: line)
	}

	func write(_ byte: Byte, line: Int) {
		code.write(byte)
		lines.write(line)
	}

	func write(value: Value, line: Int) {
		write(.constant, line: line)
		let offset = Byte(constants.write(value))
		write(offset, line: line)
	}

	func disassemble(_ name: String) {
		var disassembler = Disassembler(name: name)
		disassembler.report(chunk: self)
	}
}
