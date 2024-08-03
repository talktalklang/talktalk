//
//  Disassembler.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/2/24.
//

public struct Disassembler {
	var current = 0
	let chunk: Chunk

	public init(chunk: Chunk) {
		self.chunk = chunk
	}

	mutating public func disassemble() -> [Instruction] {
		var result: [Instruction] = []

		while let next = next() {
			result.append(next)
		}

		return result
	}

	mutating func next() -> Instruction? {
		if current == chunk.code.count {
			return nil
		}

		let index = current++
		let byte = chunk.code[index]
		guard let opcode = Opcode(rawValue: byte) else {
			fatalError("Unknown opcode: \(byte)")
		}

		switch opcode {
		case .constant:
			return constantInstruction(start: index)
		case .defClosure:
			return defClosureInstruction(start: index)
		case .jump, .jumpUnless:
			return jumpInstruction(opcode: opcode, start: index)
		case .setLocal, .getLocal:
			return localInstruction(opcode: opcode, start: index)
		case .getUpvalue:
			return upvalueInstruction(opcode: opcode, start: index)
		default:
			return Instruction(opcode: opcode, line: chunk.lines[index], offset: index, metadata: .simple)
		}
	}

	mutating func constantInstruction(start: Int) -> Instruction {
		let constant = chunk.code[current++]
		let value = chunk.constants[Int(constant)]
		let metadata = ConstantMetadata(value: value)
		return Instruction(opcode: .constant, line: chunk.lines[start], offset: start, metadata: metadata)
	}

	mutating func jumpInstruction(opcode: Opcode, start: Int) -> Instruction {
		let placeholderA = chunk.code[current++]
		let placehodlerB = chunk.code[current++]

		// Get the jump distance as a UIn16 from two bytes
		var jump = Int(placeholderA << 8)
		jump |= Int(placehodlerB)

		return Instruction(opcode: opcode, line: chunk.lines[start], offset: current, metadata: .jump(offset: jump))
	}

	mutating func localInstruction(opcode: Opcode, start: Int) -> Instruction {
		let slot = chunk.code[current++]
		let metadata = LocalMetadata(slot: slot)
		return Instruction(opcode: opcode, line: chunk.lines[start], offset: start, metadata: metadata)
	}

	mutating func defClosureInstruction(start: Int) -> Instruction {
		let closureSlot = chunk.code[current++]
		let subchunk = chunk.subchunks[Int(closureSlot)]
		let metadata = ClosureMetadata(name: nil, arity: subchunk.arity, depth: subchunk.depth, upvalueCount: 0)
		return Instruction(opcode: .defClosure, line: chunk.lines[start], offset: start, metadata: metadata)
	}

	mutating func upvalueInstruction(opcode: Opcode, start: Int) -> Instruction {
		let slot = chunk.code[current++]
		let metadata = UpvalueMetadata(slot: slot)
		return Instruction(opcode: opcode, line: chunk.lines[start], offset: start, metadata: metadata)
	}
}
