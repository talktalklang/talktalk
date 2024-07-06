//
//  Debug.swift
//
//
//  Created by Pat Nakajima on 6/30/24.
//
struct Disassembler {
	struct Instruction {
		var offset: Int
		var opcode: String
		var extra: String?
		var line: Int
		var isSameLine: Bool

		var description: String {
			let lineString = isSameLine ? "  |" : String(format: "% 3d", line)
			let parts = [
				String(format: "%04d", offset),
				lineString,
				opcode,
				extra ?? ""
			]

			return parts.joined(separator: " ")
		}
	}

	static var header: String {
		"POS\t\tLINE\tOPERATION"
	}

	var name = ""
	var instructions: [Instruction] = []
	var chunk: Chunk
	var offset = 0

	init(name: String = "", chunk: Chunk) {
		self.name = name
		self.chunk = chunk
	}

	static func dump(chunk: Chunk, into output: some OutputCollector) {
		var disassembler = Disassembler(chunk: chunk)
		output.print(Self.header)
		while let instruction = disassembler.nextInstruction() {
			output.print(instruction.description)
		}
	}

	static func dump(chunk: Chunk, ip: Int, into output: some OutputCollector) {
		var disassembler = Disassembler(chunk: chunk)
		disassembler.offset = ip
		if let out = disassembler.nextInstruction()?.description {
			output.debug(out)
		} else {
			output.debug("No instruction at \(ip)")
		}
	}

	private mutating func nextInstruction() -> Instruction? {
		if offset >= chunk.count {
			return nil
		}

		let instruction = chunk.code[offset]
		let opcode = Opcode(rawValue: instruction)

		switch opcode {
		case .constant:
			return constantInstruction("OP_CONSTANT")
		case .defineGlobal, .getGlobal, .setGlobal:
			return constantInstruction(opcode!.description)
		case .return:
			return simpleInstruction("OP_RETURN")
		case .negate:
			return simpleInstruction("OP_NEGATE")
		case .add, .subtract, .multiply, .divide:
			guard let opcode else {
				fatalError("No opcode for \(instruction)")
			}
			return simpleInstruction(opcode.description)
		case .print:
			return simpleInstruction("OP_PRINT")
		case .pop:
			return simpleInstruction("OP_POP")
		case .getLocal, .setLocal, .call:
			return byteInstruction(
				opcode!.description
			)
		case .jump, .jumpIfFalse:
			return jumpInstruction(opcode!.description, sign: 1)
		case .loop:
			return jumpInstruction(opcode!.description, sign: -1)
		case .getUpvalue, .setUpvalue:
			return byteInstruction(opcode!.description)
		case .closure:
			var offsetOffset = 1

			let constant = chunk.code[offset + offsetOffset]
			offsetOffset += 1
			let function = chunk.constants[Int(constant)].as(Function.self)
			var extra = "\(constant) \(function.name)"

			if function.upvalueCount > 0 {
				extra += "\n"
			}

			for _ in 0 ..< function.upvalueCount {
				extra += String(repeating: " ", count: 8) + " |"
				let isLocal = chunk.code[offset + offsetOffset]
				offsetOffset += 1
				let index = chunk.code[offset + offsetOffset]
				offsetOffset += 1
				extra += " \(isLocal == 1 ? "local" : "upvalue") \(index)"
			}

			defer {
				self.offset += offsetOffset
			}

			// TODO: add upvalues
			return Instruction(
				offset: offset,
				opcode: "OP_CLOSURE",
				extra: extra,
				line: line,
				isSameLine: isSameLine
			)
		default:
			return simpleInstruction(opcode!.description + " (unhandled)")
		}
	}

	private mutating func simpleInstruction(_ label: String) -> Instruction {
		defer {
			offset += 1
		}

		return Instruction(
			offset: offset,
			opcode: label,
			line: line,
			isSameLine: isSameLine
		)
	}

	private mutating func byteInstruction(_ label: String) -> Instruction {
		defer {
			offset += 2
		}

		let slot = chunk.code[offset + 1]
		let instruction = Instruction(
			offset: offset,
			opcode: label,
			extra: "slot:\(slot)",
			line: line,
			isSameLine: isSameLine
		)

		return instruction
	}

	private mutating func constantInstruction(_ label: String) -> Instruction {
		defer {
			offset += 2
		}

		let constant = Int(chunk.code[offset + 1])
		let value = chunk.constants[constant]

		return Instruction(
			offset: offset,
			opcode: label,
			extra: String(format: "%04d '\(value.description)'", constant),
			line: line,
			isSameLine: isSameLine
		)
	}

	private mutating func jumpInstruction(_ label: String, sign: Int) -> Instruction {
		var jump = chunk.code[offset + 1] << 8
		jump |= chunk.code[offset + 2]

		defer {
			offset += 3
		}

		return Instruction(
			offset: offset,
			opcode: label,
			extra: "JUMP TO \(offset + 3 + sign * Int(jump))",
			line: line,
			isSameLine: isSameLine
		)
	}

	private mutating func append(_ instruction: Instruction) {
		instructions.append(instruction)
	}

	var line: Int {
		chunk.lines[offset]
	}

	var isSameLine: Bool {
		offset > 0 && line == chunk.lines[offset - 1]
	}
}

extension Disassembler: Sequence {
	struct Iterator: IteratorProtocol {
		var disassembler: Disassembler

		init(disassembler: Disassembler) {
			self.disassembler = disassembler
		}

		mutating func next() -> Instruction? {
			disassembler.nextInstruction()
		}
	}

	func makeIterator() -> Iterator {
		Iterator(disassembler: self)
	}
}
