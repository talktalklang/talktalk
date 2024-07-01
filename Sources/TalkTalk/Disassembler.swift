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

struct Disassembler: ~Copyable {
	struct Instruction {
		var offset: Int
		var opcode: String
		var extra: String?
		var line: UInt32

		func description(_ lastLine: UInt32) -> String {
			let lineString = lastLine == line ? Array(repeating: " ", count: "\(line)".count - 1) + "|" : "\(line)"
			return "\(String(format: "%04d", offset))\t\(lineString)\t\(opcode)\t\(extra ?? "")"
		}
	}

	var name = ""
	var instructions: [Instruction] = []

	init(name: String, chunk: borrowing Chunk) {
		self.name = name

		var offset = 0
		while offset < chunk.code.count {
			offset = disassembleInstruction(chunk: chunk, offset: offset)
		}
	}

	func report() {
		var lastLine: UInt32 = 10000
		for instruction in instructions {
			print(instruction.description(lastLine))
			lastLine = instruction.line
		}
	}

	mutating func disassembleInstruction(chunk: borrowing Chunk, offset: Int) -> Int {
		let instruction = chunk.code.storage.advanced(by: offset).pointee
		let line = chunk.lines.storage.advanced(by: offset).pointee

		switch instruction {
		case Opcode.constant.rawValue:
			return constantInstruction("OP_CONSTANT", chunk: chunk, offset: offset, line: line)
		case Opcode.return.rawValue:
			return simpleInstruction("OP_RETURN", offset: offset, line: line)
		default:
			instructions.append(
				Instruction(offset: offset, opcode: "UNKNOWN INSTRUCTION \(instruction)", line: line)
			)

			return offset + 1
		}
	}

	mutating func simpleInstruction(_ label: String, offset: Int, line: UInt32) -> Int {
		instructions.append(
			Instruction(offset: offset, opcode: label, line: line)
		)

		return offset + 1
	}

	mutating func constantInstruction(_ label: String, chunk: borrowing Chunk, offset: Int, line: UInt32) -> Int {
		let constant = chunk.code.storage.advanced(by: offset).pointee
		let value = chunk.constants.storage.advanced(by: Int(constant)).pointee

		instructions.append(
			Instruction(offset: offset, opcode: label, extra: String(format: "%04d '\(value)'", constant), line: line)
		)

		return offset + 2
	}
}


