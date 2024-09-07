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
	var path: String { get }
}

public extension Disassemblable {
	func disassemble(in module: Module? = nil) throws -> [Instruction] {
		let module = module ?? {
			var stubModule = Module(name: "Stub", symbols: [:])
			stubModule.chunks = if let chunk = self as? Chunk {
				[
					StaticChunk(chunk: chunk)
				]
			} else if let chunk = self as? StaticChunk {
				[
					chunk
				]
			} else {
				[]
			}
			return stubModule
		}()

		var disassembler = Disassembler(chunk: self, module: module)
		return try disassembler.disassemble()
	}

	@discardableResult func dump(in module: Module) throws -> String {
		var result = "[\(name) locals: \(localsCount), upvalues: \(upvalueCount)]\n"
		result += try disassemble(in: module).map(\.description).joined(separator: "\n") + "\n"
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

	public var path: String {
		debugInfo.path
	}
}

extension Chunk: Disassemblable {}

public enum DisassemblerError: Error {
	case unknownOpcode(Byte)
}

public struct Disassembler<Chunk: Disassemblable> {
	public var current = 0
	let module: Module
	let chunk: Disassemblable

	public init(chunk: Chunk, module: Module) {
		self.chunk = chunk
		self.module = module
	}

	public mutating func disassemble() throws -> [Instruction] {
		var result: [Instruction] = []

		while let next = try next() {
			result.append(next)
		}

		return result
	}

	public mutating func next() throws -> Instruction? {
		if current == chunk.code.count {
			return nil
		}

		let index = current++
		let byte = chunk.code[index]
		guard let opcode = Opcode(rawValue: byte) else {
			throw DisassemblerError.unknownOpcode(byte)
		}

		switch opcode {
		case .constant:
			return constantInstruction(start: index)
		case .defClosure:
			return defClosureInstruction(start: index)
		case .jump, .jumpUnless, .loop, .matchCase:
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
		case .getEnumCase:
			return enumCaseInstruction(opcode: opcode, start: index)
		case .initArray:
			return initArrayInstruction(start: index)
		default:
			return Instruction(path: self.chunk.path, opcode: opcode, offset: index, line: chunk.lines[index], metadata: .simple)
		}
	}

	mutating func enumCaseInstruction(opcode: Opcode, start: Int) -> Instruction {
		let enumByte = chunk.code[current++]
		let caseByte = chunk.code[current++]

		return Instruction(path: chunk.path, opcode: opcode, offset: start, line: chunk.lines[start], metadata: .enum(enum: Int(enumByte), case: Int(caseByte)))
	}

	mutating func initArrayInstruction(start: Int) -> Instruction {
		let count = chunk.code[current++]
		for _ in 0..<count {
			current++
		}

		return Instruction(path: self.chunk.path, opcode: .initArray, offset: start, line: chunk.lines[start], metadata: InitArrayMetadata(elementCount: Int(count)))
	}

	mutating func constantInstruction(start: Int) -> Instruction {
		let constant = chunk.code[current++]
		let value = chunk.constants[Int(constant)]
		let metadata = ConstantMetadata(value: value)
		return Instruction(path: self.chunk.path, opcode: .constant, offset: start, line: chunk.lines[start], metadata: metadata)
	}

	mutating func jumpInstruction(opcode: Opcode, start: Int) -> Instruction {
		let placeholderA = chunk.code[current++]
		let placehodlerB = chunk.code[current++]

		// Get the jump distance as a UIn16 from two bytes
		var jump = Int(placeholderA << 8)
		jump |= Int(placehodlerB)

		let metadata: any InstructionMetadata = opcode == .loop ? .loop(back: jump) : .jump(offset: jump)
		return Instruction(path: self.chunk.path, opcode: opcode, offset: start, line: chunk.lines[start], metadata: metadata)
	}

	mutating func variableInstruction(opcode: Opcode, start: Int, type: VariableMetadata.VariableType) -> Instruction {
		let slot = chunk.code[current++]

		let name = switch type {
		case .local:
			chunk.localNames[Int(slot)]
		case .global:
			"slot: \(slot)"
		case .builtin:
			[
				"print",
				"_allocate",
				"_free",
				"_deref",
				"_storePtr",
				"_hash",
				"_cast"
			][Int(slot)]
		case .struct:
			"slot: \(slot)"
		case .property:
			"slot: \(slot)"
		case .moduleFunction:
			"slot: \(slot)"
		}

		let metadata = VariableMetadata(slot: slot, name: name, type: type)
		return Instruction(path: self.chunk.path, opcode: opcode, offset: start, line: chunk.lines[start], metadata: metadata)
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
		return Instruction(path: self.chunk.path, opcode: .defClosure, offset: start, line: chunk.lines[start], metadata: metadata)
	}

	mutating func upvalueInstruction(opcode: Opcode, start: Int) -> Instruction {
		let slot = chunk.code[current++]
		let metadata = UpvalueMetadata(slot: slot, name: chunk.upvalueNames[Int(slot)])
		return Instruction(path: self.chunk.path, opcode: opcode, offset: start, line: chunk.lines[start], metadata: metadata)
	}

	mutating func getPropertyInstruction(opcode: Opcode, start: Int, type _: VariableMetadata.VariableType) -> Instruction {
		let slot = chunk.code[current++]
		let options = chunk.code[current++]

		let metadata = GetPropertyMetadata(slot: Int(slot), options: PropertyOptions(rawValue: options))
		return Instruction(path: self.chunk.path, opcode: opcode, offset: start, line: chunk.lines[start], metadata: metadata)
	}
}
