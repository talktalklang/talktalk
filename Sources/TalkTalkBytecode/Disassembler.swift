//
//  Disassembler.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/2/24.
//

import Foundation

public protocol Disassemblable {
	var name: String { get }
	var code: ContiguousArray<Code> { get }
	var lines: [UInt32] { get }
	var constants: [Value] { get }
	var arity: Byte { get }
	var locals: [Symbol] { get }
	var capturedLocals: Set<Symbol> { get }
	var depth: Byte { get }
	var path: String { get }
}

public extension Disassemblable {
	func disassemble(in module: Module? = nil) throws -> [Instruction] {
		let module = module ?? {
			var stubModule = Module(name: "Stub", symbols: [:])
			stubModule.chunks = if let chunk = self as? Chunk {
				[
					chunk.symbol: StaticChunk(chunk: chunk)
				]
			} else if let chunk = self as? StaticChunk {
				[
					chunk.symbol:	chunk
				]
			} else {
				[:]
			}
			return stubModule
		}()

		var disassembler = Disassembler(chunk: self, module: module)
		return try disassembler.disassemble()
	}

	@discardableResult func dump(in module: Module) throws -> String {
		var result = "[\(name)]\n"
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
	
	public var locals: [Symbol] {
		debugInfo.locals
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
	case unknownOpcode(Code), chunkNotFound(Symbol)
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
		guard case let .opcode(opcode) = byte else {
			throw DisassemblerError.unknownOpcode(byte)
		}

		switch opcode {
		case .constant:
			return try constantInstruction(start: index)
		case .defClosure:
			return try defClosureInstruction(start: index)
		case .jump, .jumpUnless, .loop:
			return try jumpInstruction(opcode: opcode, start: index)
		case .setCapture, .getCapture:
			return try captureInstruction(opcode: opcode, start: index)
		case .setLocal, .getLocal:
			return try variableInstruction(opcode: opcode, start: index, type: .local)
		case .getModuleFunction, .setModuleFunction:
			return try variableInstruction(opcode: opcode, start: index, type: .moduleFunction)
		case .getModuleValue, .setModuleValue:
			return try variableInstruction(opcode: opcode, start: index, type: .global)
		case .getStruct, .setStruct:
			return try variableInstruction(opcode: opcode, start: index, type: .struct)
		case .getProperty:
			return try getPropertyInstruction(opcode: opcode, start: index, type: .property)
		case .setProperty:
			return try variableInstruction(opcode: opcode, start: index, type: .property)
		case .setBuiltin, .getBuiltin:
			return try variableInstruction(opcode: opcode, start: index, type: .builtin)
		case .callChunkID:
			return try variableInstruction(opcode: opcode, start: index, type: .global)
		case .initArray:
			return try initArrayInstruction(start: index)
		default:
			return Instruction(path: self.chunk.path, opcode: opcode, offset: index, line: chunk.lines[index], metadata: .simple)
		}
	}

	mutating func initArrayInstruction(start: Int) throws -> Instruction {
		let count = try chunk.code[current++].asByte()
		for _ in 0..<count {
			current++
		}

		return Instruction(path: self.chunk.path, opcode: .initArray, offset: start, line: chunk.lines[start], metadata: InitArrayMetadata(elementCount: Int(count)))
	}

	mutating func captureInstruction(opcode: Opcode, start: Int) throws -> Instruction {
		let capture = try chunk.code[current++].asCapture()
		return Instruction(
			path: chunk.path,
			opcode: opcode,
			offset: start,
			line: chunk.lines[start],
			metadata: .capture(name: capture.name, capture.location)
		)
	}

	mutating func constantInstruction(start: Int) throws -> Instruction {
		let constant = try chunk.code[current++].asByte()
		let value = chunk.constants[Int(constant)]
		let metadata = ConstantMetadata(value: value)
		return Instruction(path: self.chunk.path, opcode: .constant, offset: start, line: chunk.lines[start], metadata: metadata)
	}

	mutating func jumpInstruction(opcode: Opcode, start: Int) throws -> Instruction {
		let placeholderA = try chunk.code[current++].asByte()
		let placehodlerB = try chunk.code[current++].asByte()

		// Get the jump distance as a UIn16 from two bytes
		var jump = Int(placeholderA << 8)
		jump |= Int(placehodlerB)

		let metadata: any InstructionMetadata = opcode == .loop ? .loop(back: jump) : .jump(offset: jump)
		return Instruction(path: self.chunk.path, opcode: opcode, offset: start, line: chunk.lines[start], metadata: metadata)
	}

	mutating func variableInstruction(opcode: Opcode, start: Int, type: VariableMetadata.VariableType) throws -> Instruction {
		let symbol = try chunk.code[current++].asSymbol()

		let metadata = VariableMetadata(symbol: symbol, type: type)
		return Instruction(path: self.chunk.path, opcode: opcode, offset: start, line: chunk.lines[start], metadata: metadata)
	}

	mutating func defClosureInstruction(start: Int) throws -> Instruction {
		let closureSlot = try chunk.code[current++].asSymbol()
		guard let subchunk = module.chunks[closureSlot] else {
			throw DisassemblerError.chunkNotFound(closureSlot)
		}

		let metadata = ClosureMetadata(name: subchunk.name, arity: subchunk.arity, depth: subchunk.depth)
		return Instruction(
			path: self.chunk.path,
			opcode: .defClosure,
			offset: start,
			line: chunk.lines[start],
			metadata: metadata
		)
	}

	mutating func getPropertyInstruction(opcode: Opcode, start: Int, type: VariableMetadata.VariableType) throws -> Instruction {
		let symbol = try chunk.code[current++].asSymbol()
		let options = try chunk.code[current++].asByte()

		let metadata = GetPropertyMetadata(
			symbol: symbol,
			options: PropertyOptions(rawValue: options)
		)

		return Instruction(path: self.chunk.path, opcode: opcode, offset: start, line: chunk.lines[start], metadata: metadata)
	}
}
