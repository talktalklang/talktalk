//
//  Disassembler.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/2/24.
//

public struct Disassembler {
	public var current = 0
	let chunk: Chunk

	public init(chunk: Chunk) {
		self.chunk = chunk
	}

	public mutating func disassemble() -> [Instruction] {
		var result: [Instruction] = []

		while let next = next() {
			result.append(next)
		}

		return result
	}

	public mutating func next() -> Instruction? {
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
		case .jump, .jumpUnless, .loop:
			return jumpInstruction(opcode: opcode, start: index)
		case .setLocal, .getLocal:
			return variableInstruction(opcode: opcode, start: index)
		case .getModuleFunction, .setModuleFunction:
			return variableInstruction(opcode: opcode, start: index)
		case .getModuleValue, .setModuleValue:
			return variableInstruction(opcode: opcode, start: index)
		case .getStruct, .setStruct:
			return variableInstruction(opcode: opcode, start: index)
		case .getProperty:
			return getPropertyInstruction(opcode: opcode, start: index)
		case .setProperty:
			return variableInstruction(opcode: opcode, start: index)
		case .setBuiltin, .getBuiltin:
			return variableInstruction(opcode: opcode, start: index)
		case .callChunkID:
			return variableInstruction(opcode: opcode, start: index)
		default:
			return Instruction(opcode: opcode, offset: index, line: chunk.lines[index], metadata: .simple)
		}
	}

	mutating func constantInstruction(start: Int) -> Instruction {
		let constant = chunk.code[current++]
		let value = chunk.constants[Int(constant)]
		let metadata = ConstantMetadata(value: value)
		return Instruction(opcode: .constant, offset: start, line: chunk.lines[start], metadata: metadata)
	}

	mutating func jumpInstruction(opcode: Opcode, start: Int) -> Instruction {
		let placeholderA = chunk.code[current++]
		let placehodlerB = chunk.code[current++]

		// Get the jump distance as a UIn16 from two bytes
		var jump = Int(placeholderA << 8)
		jump |= Int(placehodlerB)

		let metadata: any InstructionMetadata = opcode == .loop ? .loop(back: jump) : .jump(offset: jump)
		return Instruction(opcode: opcode, offset: start, line: chunk.lines[start], metadata: metadata)
	}

	mutating func variableInstruction(opcode: Opcode, start: Int) -> Instruction {
		let a = chunk.code[current++]
		let b = chunk.code[current++]

		let pointer = Pointer(bytes: (a, b))

		let name = chunk.localNames[pointer] ?? ""

		let metadata = VariableMetadata(pointer: pointer, name: name)
		return Instruction(opcode: opcode, offset: start, line: chunk.lines[start], metadata: metadata)
	}

	mutating func defClosureInstruction(start: Int) -> Instruction {
		let closureSlot = chunk.code[current++]
		let subchunk = chunk.getChunk(at: Int(closureSlot))
		let localA = chunk.code[current++]
		let localB = chunk.code[current++]
		let localSlot = Pointer(bytes: (localA, localB))

		let name = if localSlot != .stack(0) {
			chunk.localNames[localSlot]
		} else {
			""
		}

		let metadata = ClosureMetadata(name: name, arity: subchunk.arity, depth: subchunk.depth)
		return Instruction(opcode: .defClosure, offset: start, line: chunk.lines[start], metadata: metadata)
	}

	mutating func getPropertyInstruction(opcode: Opcode, start: Int) -> Instruction {
		let slot = chunk.code[current++]
		let options = chunk.code[current++]

		let metadata = GetPropertyMetadata(slot: Int(slot), options: PropertyOptions(rawValue: options))
		return Instruction(opcode: opcode, offset: start, line: chunk.lines[start], metadata: metadata)
	}
}
