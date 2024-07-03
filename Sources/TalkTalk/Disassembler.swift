//
//  Debug.swift
//
//
//  Created by Pat Nakajima on 6/30/24.
//
#if canImport(Glibc)
	import Glibc
#elseif canImport(Foundation)
	import Foundation
#endif

struct Disassembler<Output: OutputCollector>: ~Copyable {
	struct Instruction {
		var offset: Int
		var opcode: String
		var extra: String?
		var line: Int
		var isSameLine: Bool

		var description: String {
			let lineString = isSameLine ? "   |" : String(format: "%04d", line)
			let extra = if let extra {
				"|\t\(extra)"
			} else {
				""
			}
			return "\(String(format: "%04d", offset))\t\(lineString)\t\(opcode)\t\(extra)"
		}
	}

	static var header: String {
		"POS\t\tLINE\tOPERATION"
	}

	static func report(chunk: borrowing Chunk, output: Output) {
		var diassembler = Disassembler(output: output)
		diassembler.report(chunk: chunk)
	}

	var name = ""
	var instructions: [Instruction] = []
	var output: Output

	init(name: String = "", output: Output) {
		self.name = name
		self.output = output
	}

	mutating func report(byte: UnsafeMutablePointer<Byte>, in chunk: borrowing Chunk) {
		_ = disassembleInstruction(chunk: chunk, offset: byte - chunk.code.storage)

		for instruction in instructions {
			output.debug(instruction.description)
		}
	}

	mutating func report(chunk: borrowing Chunk) {
		output.print(Disassembler.header)

		var offset = 0
		while offset < chunk.code.count {
			offset = disassembleInstruction(chunk: chunk, offset: offset)
		}

		for instruction in instructions {
			output.debug(instruction.description)
		}
	}

	mutating func disassembleInstruction(chunk: borrowing Chunk, offset: Int) -> Int {
		let instruction = chunk.code.storage.advanced(by: offset).pointee
		let line = chunk.lines.storage.advanced(by: offset).pointee

		let isSameLine = offset > 0 && line == chunk.lines.storage.advanced(by: offset - 1).pointee
		let opcode = Opcode(rawValue: instruction)

		switch opcode {
		case .constant:
			return constantInstruction("OP_CONSTANT", chunk: chunk, offset: offset, line: line, isSameLine: isSameLine)
		case .return:
			return simpleInstruction("OP_RETURN", offset: offset, line: line, isSameLine: isSameLine)
		case .negate:
			return simpleInstruction("OP_NEGATE", offset: offset, line: line, isSameLine: isSameLine)
		case .add, .subtract, .multiply, .divide:
			guard let opcode else {
				fatalError("No opcode for \(instruction)")
			}
			return simpleInstruction(opcode.description, offset: offset, line: line, isSameLine: isSameLine)
		case .print:
			return simpleInstruction("OP_PRINT", offset: offset, line: line, isSameLine: isSameLine)
		case .pop:
			return simpleInstruction("OP_POP", offset: offset, line: line, isSameLine: isSameLine)
		case .jump, .jumpIfFalse:
			return jumpInstruction(opcode!.description, chunk: chunk, sign: 1, offset: offset, line: line, isSameLine: isSameLine)
		default:
			return simpleInstruction(opcode!.description, offset: offset, line: line, isSameLine: isSameLine)
		}
	}

	mutating func simpleInstruction(_ label: String, offset: Int, line: Int, isSameLine: Bool) -> Int {
		append(
			Instruction(offset: offset, opcode: label, line: line, isSameLine: isSameLine)
		)

		return offset + 1
	}

	mutating func constantInstruction(_ label: String, chunk: borrowing Chunk, offset: Int, line: Int, isSameLine: Bool) -> Int {
		let constant = chunk.code.storage.advanced(by: offset + 1).pointee
		let value = chunk.constants.storage.advanced(by: Int(constant)).pointee

		append(
			Instruction(
				offset: offset,
				opcode: label,
				extra: String(format: "%04d '\(value.description)'", constant),
				line: line,
				isSameLine: isSameLine
			)
		)

		return offset + 2
	}

	mutating func jumpInstruction(_ label: String, chunk: borrowing Chunk, sign: Int, offset: Int, line: Int, isSameLine: Bool) -> Int {
		var jump = chunk.code.storage.advanced(by: offset + 1).pointee << 8
		jump |= chunk.code.storage.advanced(by: offset + 2).pointee

		append(
			Instruction(
				offset: offset,
				opcode: label,
				extra: "JUMP TO \(offset + 3 + sign * Int(jump))",
				line: line,
				isSameLine: isSameLine
			)
		)

		return offset + 3
	}

	mutating func append(_ instruction: Instruction) {
		instructions.append(instruction)
	}
}
