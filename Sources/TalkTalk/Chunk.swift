//
//  Chunk.swift
//
//
//  Created by Pat Nakajima on 6/30/24.
//

public class Chunk: Hashable {
	public static func == (lhs: Chunk, rhs: Chunk) -> Bool {
		lhs.hashValue == rhs.hashValue
	}

	var code = DynamicArray<Byte>()
	var constants = DynamicArray<Value>()
	var lines = DynamicArray<Int>()

	public func hash(into hasher: inout Swift.Hasher) {
		hasher.combine(code.storage.hashValue)
		hasher.combine(constants.storage.hashValue)
		hasher.combine(lines.storage.hashValue)
	}

	var count: Int {
		code.count
	}

	func write(constant value: Value) -> Byte {
		Byte(constants.write(value))
	}

	func write(_ opcode: Opcode, line: Int) {
		write(opcode.byte, line: line)
	}

	func write(_ byte: Byte, line: Int) {
		code.write(byte)
		lines.write(line)
	}

	func write(value: consuming Value, line: Int) {
		write(.constant, line: line)
		let offset = Byte(constants.write(value))
		write(offset, line: line)
	}

	func disassemble<Output: OutputCollector>(_ name: String, to output: Output) {
		var disassembler = Disassembler(name: name, output: output)
		disassembler.report(chunk: self)
	}
}
