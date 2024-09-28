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
	var data: [StaticData] { get }
	var debugLogs: [String] { get }
	var lines: [UInt32] { get }
	var constants: [Value] { get }
	var arity: Byte { get }
	var locals: [StaticSymbol] { get }
	var capturedLocals: Set<StaticSymbol> { get }
	var depth: Byte { get }
	var path: String { get }
}

public extension Disassemblable {
	func disassemble(in module: Module? = nil) throws -> [Instruction] {
		let module = module ?? {
			var stubModule = Module(name: "Stub", symbols: [:])
			stubModule.chunks = if let chunk = self as? Chunk {
				[
					chunk.symbol.asStatic(): StaticChunk(chunk: chunk),
				]
			} else if let chunk = self as? StaticChunk {
				[
					chunk.symbol.asStatic(): chunk,
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

	public var debugLogs: [String] {
		debugInfo.debugLogs
	}

	public var locals: [StaticSymbol] {
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
	case unknownOpcode(Code), chunkNotFound(StaticSymbol)
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
		let code = chunk.code[index]
		guard case let .opcode(opcode) = code else {
			throw DisassemblerError.unknownOpcode(code)
		}

		switch opcode {
		case .get:
			return try variableInstruction(opcode: .get, start: index, type: .get)
		case .invokeMethod:
			return try variableInstruction(opcode: .invokeMethod, start: index, type: .invokeMethod)
		case .data:
			return try dataInstruction(start: index)
		case .binding:
			return try bindingInstruction(start: index)
		case .matchBegin:
			return try variableInstruction(opcode: .matchBegin, start: index, type: .matchBegin)
		case .constant:
			return try constantInstruction(start: index)
		case .defClosure:
			return try defClosureInstruction(start: index)
		case .jump, .jumpUnless, .loop, .matchCase:
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
		case .getProperty, .getMethod:
			return try getPropertyInstruction(opcode: opcode, start: index, type: .property)
		case .setProperty:
			return try variableInstruction(opcode: opcode, start: index, type: .property)
		case .setBuiltin, .getBuiltin:
			return try variableInstruction(opcode: opcode, start: index, type: .builtin)
		case .callChunkID:
			return try variableInstruction(opcode: opcode, start: index, type: .global)
		case .getEnum:
			return try variableInstruction(opcode: opcode, start: index, type: .enum)
		case .initArray:
			return try initArrayInstruction(start: index)
		case .initDict:
			return try initDictInstruction(start: index)
		case .debugPrint:
			return try debugPrintInstruction(start: index)
		default:
			return Instruction(path: chunk.path, opcode: opcode, offset: index, line: chunk.lines[index], metadata: .simple)
		}
	}

	mutating func dataInstruction(start: Int) throws -> Instruction {
		let i = try chunk.code[current++].asByte()
		let data = chunk.data[Int(i)]

		return Instruction(
			path: chunk.path,
			opcode: .data,
			offset: start,
			line: chunk.lines[start],
			metadata: .data(data)
		)
	}

	mutating func debugPrintInstruction(start: Int) throws -> Instruction {
		let i = try chunk.code[current++].asByte()
		let message = chunk.debugLogs[Int(i)]
		return Instruction(
			path: chunk.path,
			opcode: .debugPrint,
			offset: start,
			line: chunk.lines[start],
			metadata: .debug(message)
		)
	}

	mutating func bindingInstruction(start: Int) throws -> Instruction {
		let symbol = try chunk.code[current++].asSymbol()
		return Instruction(
			path: chunk.path,
			opcode: .binding,
			offset: start,
			line: chunk.lines[start],
			metadata: .binding(symbol)
		)
	}

	mutating func initArrayInstruction(start: Int) throws -> Instruction {
		let count = try Int(chunk.code[current++].asByte())

		return Instruction(path: chunk.path, opcode: .initArray, offset: start, line: chunk.lines[start], metadata: InitArrayMetadata(elementCount: count))
	}

	mutating func initDictInstruction(start: Int) throws -> Instruction {
		let count = try Int(chunk.code[current++].asByte())

		return Instruction(path: chunk.path, opcode: .initDict, offset: start, line: chunk.lines[start], metadata: InitDictionaryMetadata(elementCount: count))
	}

	mutating func captureInstruction(opcode: Opcode, start: Int) throws -> Instruction {
		let capture = try chunk.code[current++].asCapture()
		return Instruction(
			path: chunk.path,
			opcode: opcode,
			offset: start,
			line: chunk.lines[start],
			metadata: .capture(capture.symbol, capture.location)
		)
	}

	mutating func constantInstruction(start: Int) throws -> Instruction {
		let constant = try chunk.code[current++].asByte()
		let value = chunk.constants[Int(constant)]
		let metadata = ConstantMetadata(value: value)
		return Instruction(path: chunk.path, opcode: .constant, offset: start, line: chunk.lines[start], metadata: metadata)
	}

	mutating func jumpInstruction(opcode: Opcode, start: Int) throws -> Instruction {
		let placeholderA = try chunk.code[current++].asByte()
		let placehodlerB = try chunk.code[current++].asByte()

		// Get the jump distance as a UIn16 from two bytes
		var jump = Int(placeholderA << 8)
		jump |= Int(placehodlerB)

		let metadata: any InstructionMetadata = opcode == .loop ? .loop(back: jump) : .jump(offset: jump)
		return Instruction(path: chunk.path, opcode: opcode, offset: start, line: chunk.lines[start], metadata: metadata)
	}

	mutating func variableInstruction(opcode: Opcode, start: Int, type: VariableMetadata.VariableType) throws -> Instruction {
		let symbol = try chunk.code[current++].asSymbol()

		let metadata = VariableMetadata(symbol: symbol, type: type)
		return Instruction(path: chunk.path, opcode: opcode, offset: start, line: chunk.lines[start], metadata: metadata)
	}

	mutating func defClosureInstruction(start: Int) throws -> Instruction {
		let closureSlot = try chunk.code[current++].asSymbol()
		guard let subchunk = module.chunks[closureSlot] else {
			throw DisassemblerError.chunkNotFound(closureSlot)
		}

		let metadata = ClosureMetadata(name: subchunk.name, arity: subchunk.arity, depth: subchunk.depth)
		return Instruction(
			path: chunk.path,
			opcode: .defClosure,
			offset: start,
			line: chunk.lines[start],
			metadata: metadata
		)
	}

	mutating func getPropertyInstruction(opcode: Opcode, start: Int, type _: VariableMetadata.VariableType) throws -> Instruction {
		let symbol = try chunk.code[current++].asSymbol()

		let metadata = GetPropertyMetadata(
			symbol: symbol
		)

		return Instruction(path: chunk.path, opcode: opcode, offset: start, line: chunk.lines[start], metadata: metadata)
	}
}
