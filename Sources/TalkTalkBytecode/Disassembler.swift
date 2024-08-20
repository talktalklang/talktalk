//
//  Disassembler.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/2/24.
//

import Foundation

public protocol Disassemblable {
	var name: String { get }
	var code: ContiguousArray<Byte> { get }
	var lines: [UInt32] { get }
	var constants: [Value] { get }
	var arity: Byte { get }
	var localsCount: Byte { get }
	var localNames: [String] { get }
	var upvalueNames: [String] { get }
	var upvalueCount: Byte { get }
	var depth: Byte { get }
}

public extension Disassemblable {
	func disassemble(in module: Module? = nil) -> [Instruction] {
		let module = module ?? {
			var stubModule = Module(name: "Stub", symbols: [:])
			stubModule.chunks = if let chunk = self as? Chunk {
				[
					StaticChunk(chunk: chunk)
				]
			} else {
				[
					self as! StaticChunk
				]
			}
			return stubModule
		}()

		var disassembler = Disassembler(chunk: self, module: module)
		return disassembler.disassemble()
	}

	@discardableResult func dump(in module: Module) -> String {
		var result = "[\(name) locals: \(localsCount), upvalues: \(upvalueCount)]\n"
		result += disassemble(in: module).map(\.description).joined(separator: "\n") + "\n"

//		for subchunk in subchunks {
//			result += subchunk.dump()
//		}

		result += "\n"

		FileHandle.standardError.write(Data(result.utf8))
		return result
	}
}

extension StaticChunk: Disassemblable {
	public var lines: [UInt32] {
		debugInfo.lines
	}
	
	public var localNames: [String] {
		debugInfo.localNames
	}
	
	public var upvalueNames: [String] {
		debugInfo.upvalueNames
	}
	
	public var depth: Byte {
		debugInfo.depth
	}
}

extension Chunk: Disassemblable {}

public struct Disassembler<Chunk: Disassemblable> {
	public var current = 0
	let module: Module
	let chunk: Disassemblable

	public init(chunk: Chunk, module: Module) {
		self.chunk = chunk
		self.module = module
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
			return variableInstruction(opcode: opcode, start: index, type: .local)
		case .getModuleFunction, .setModuleFunction:
			return variableInstruction(opcode: opcode, start: index, type: .moduleFunction)
		case .getModuleValue, .setModuleValue:
			return variableInstruction(opcode: opcode, start: index, type: .global)
		case .getStruct, .setStruct:
			return variableInstruction(opcode: opcode, start: index, type: .struct)
		case .getProperty:
			return getPropertyInstruction(opcode: opcode, start: index, type: .property)
		case .setProperty:
			return variableInstruction(opcode: opcode, start: index, type: .property)
		case .setBuiltin, .getBuiltin:
			return variableInstruction(opcode: opcode, start: index, type: .builtin)
		case .callChunkID:
			return variableInstruction(opcode: opcode, start: index, type: .global)
		case .getUpvalue, .setUpvalue:
			return upvalueInstruction(opcode: opcode, start: index)
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

	mutating func variableInstruction(opcode: Opcode, start: Int, type: VariableMetadata.VariableType) -> Instruction {
		let slot = chunk.code[current++]

		let name = switch type {
		case .local:
			chunk.localNames[Int(slot)]
		case .global:
			"slot: \(slot)"
		case .builtin:
			"builtin \(slot)"
		case .struct:
			"slot: \(slot)"
		case .property:
			"slot: \(slot)"
		case .moduleFunction:
			module.chunks[Int(slot)].name
		}

		let metadata = VariableMetadata(slot: slot, name: name, type: type)
		return Instruction(opcode: opcode, offset: start, line: chunk.lines[start], metadata: metadata)
	}

	mutating func defClosureInstruction(start: Int) -> Instruction {
		let closureSlot = chunk.code[current++]
		let subchunk = module.chunks[Int(closureSlot)]

		var upvalues: [ClosureMetadata.Upvalue] = []
		for _ in 0 ..< subchunk.upvalueCount {
			let isLocal = chunk.code[current++] == 1
			let index = chunk.code[current++]

			upvalues.append(ClosureMetadata.Upvalue(isLocal: isLocal, index: index))
		}

		let metadata = ClosureMetadata(name: subchunk.name, arity: subchunk.arity, depth: subchunk.depth, upvalues: upvalues)
		return Instruction(opcode: .defClosure, offset: start, line: chunk.lines[start], metadata: metadata)
	}

	mutating func upvalueInstruction(opcode: Opcode, start: Int) -> Instruction {
		let slot = chunk.code[current++]
		let metadata = UpvalueMetadata(slot: slot, name: chunk.upvalueNames[Int(slot)])
		return Instruction(opcode: opcode, offset: start, line: chunk.lines[start], metadata: metadata)
	}

	mutating func getPropertyInstruction(opcode: Opcode, start: Int, type _: VariableMetadata.VariableType) -> Instruction {
		let slot = chunk.code[current++]
		let options = chunk.code[current++]

		let metadata = GetPropertyMetadata(slot: Int(slot), options: PropertyOptions(rawValue: options))
		return Instruction(opcode: opcode, offset: start, line: chunk.lines[start], metadata: metadata)
	}
}
