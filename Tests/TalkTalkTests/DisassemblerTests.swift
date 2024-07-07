//
//  DisassemblerTests.swift
//
//
//  Created by Pat Nakajima on 7/6/24.
//
@testable import TalkTalk
import Testing

struct DisassemblerTests {
	func instruction<Metadata: Disassembler.Metadata>(
		from chunk: Chunk,
		metadata: Metadata.Type?
	) -> (
		line: Int,
		opcode: String,
		metadata: Metadata?,
		isSameLine: Bool,
		offset: Int,
		disassemblerOffset: Int
	) {
		var disassembler = Disassembler(chunk: chunk)
		let instructionOptional = disassembler.nextInstruction()
		let instruction = try! #require(instructionOptional)

		return (
			line: instruction.line,
			opcode: instruction.opcode,
			metadata: instruction.metadata as? Metadata,
			isSameLine: instruction.isSameLine,
			offset: instruction.offset,
			disassemblerOffset: disassembler.offset
		)
	}

	func instruction(
		from chunk: Chunk
	) -> (
		line: Int,
		opcode: String,
		isSameLine: Bool,
		offset: Int,
		disassemblerOffset: Int
	) {
		var disassembler = Disassembler(chunk: chunk)
		let instructionOptional = disassembler.nextInstruction()
		let instruction = try! #require(instructionOptional)

		return (
			line: instruction.line,
			opcode: instruction.opcode,
			isSameLine: instruction.isSameLine,
			offset: instruction.offset,
			disassemblerOffset: disassembler.offset
		)
	}

	@Test("OP_CONSTANT") func constantTest() {
		var chunk = Chunk()

		chunk.write(value: .nil, line: 123)

		#expect(instruction(from: chunk, metadata: ConstantMetadata.self) == (
			line: 123,
			opcode: "OP_CONSTANT",
			metadata: ConstantMetadata(byte: 0, value: .nil),
			isSameLine: false,
			offset: 0,
			disassemblerOffset: 2
		))
	}

	@Test("OP_NIL") func nilTest() throws {
		var chunk = Chunk()

		chunk.write(.nil, line: 123)

		#expect(instruction(from: chunk) == (
			line: 123,
			opcode: "OP_NIL",
			isSameLine: false,
			offset: 0,
			disassemblerOffset: 1
		))
	}

	@Test("OP_TRUE") func trueTest() throws {
		var chunk = Chunk()

		chunk.write(.true, line: 123)

		#expect(instruction(from: chunk) == (
			line: 123,
			opcode: "OP_TRUE",
			isSameLine: false,
			offset: 0,
			disassemblerOffset: 1
		))
	}

	@Test("OP_FALSE") func falseTest() throws {
		var chunk = Chunk()

		chunk.write(.false, line: 123)

		#expect(instruction(from: chunk) == (
			line: 123,
			opcode: "OP_FALSE",
			isSameLine: false,
			offset: 0,
			disassemblerOffset: 1
		))
	}

	@Test("OP_POP") func popTest() throws {
		var chunk = Chunk()

		chunk.write(.pop, line: 123)

		#expect(instruction(from: chunk) == (
			line: 123,
			opcode: "OP_POP",
			isSameLine: false,
			offset: 0,
			disassemblerOffset: 1
		))
	}

	@Test("OP_GET_LOCAL") func getLocal() throws {
		var chunk = Chunk()

		chunk.write(.getLocal, line: 123)
		chunk.write(4, line: 123)

		#expect(instruction(from: chunk, metadata: ByteMetadata.self) == (
			line: 123,
			opcode: "OP_GET_LOCAL",
			metadata: ByteMetadata(byte: 4),
			isSameLine: false,
			offset: 0,
			disassemblerOffset: 2
		))
	}

	@Test("OP_SET_LOCAL") func setLocal() throws {
		var chunk = Chunk()

		chunk.write(.setLocal, line: 123)
		chunk.write(4, line: 123)

		#expect(instruction(from: chunk, metadata: ByteMetadata.self) == (
			line: 123,
			opcode: "OP_SET_LOCAL",
			metadata: ByteMetadata(byte: 4),
			isSameLine: false,
			offset: 0,
			disassemblerOffset: 2
		))
	}

	@Test("OP_GET_GLOBAL") func getGlobal() throws {
		var chunk = Chunk()

		let constant = chunk.make(constant: .nil)
		chunk.write(.getGlobal, line: 123)
		chunk.write(constant, line: 123)

		#expect(instruction(from: chunk, metadata: ConstantMetadata.self) == (
			line: 123,
			opcode: "OP_GET_GLOBAL",
			metadata: ConstantMetadata(byte: 0, value: .nil),
			isSameLine: false,
			offset: 0,
			disassemblerOffset: 2
		))
	}

	@Test("OP_DEFINE_GLOBAL") func defineGlobal() throws {
		var chunk = Chunk()

		let constant = chunk.make(constant: .nil)
		chunk.write(.defineGlobal, line: 123)
		chunk.write(constant, line: 123)

		#expect(instruction(from: chunk, metadata: ConstantMetadata.self) == (
			line: 123,
			opcode: "OP_DEFINE_GLOBAL",
			metadata: ConstantMetadata(byte: 0, value: .nil),
			isSameLine: false,
			offset: 0,
			disassemblerOffset: 2
		))
	}

	@Test("OP_SET_GLOBAL") func setGlobal() throws {
		var chunk = Chunk()

		let constant = chunk.make(constant: .nil)
		chunk.write(.setGlobal, line: 123)
		chunk.write(constant, line: 123)

		#expect(instruction(from: chunk, metadata: ConstantMetadata.self) == (
			line: 123,
			opcode: "OP_SET_GLOBAL",
			metadata: ConstantMetadata(byte: 0, value: .nil),
			isSameLine: false,
			offset: 0,
			disassemblerOffset: 2
		))
	}

	@Test("OP_GET_UPVALUE") func getUpvalue() throws {
		var chunk = Chunk()

		chunk.write(.getUpvalue, line: 123)
		chunk.write(16, line: 123)

		#expect(instruction(from: chunk, metadata: ByteMetadata.self) == (
			line: 123,
			opcode: "OP_GET_UPVALUE",
			metadata: ByteMetadata(byte: 16),
			isSameLine: false,
			offset: 0,
			disassemblerOffset: 2
		))
	}

	@Test("OP_SET_UPVALUE") func setUpvalue() throws {
		var chunk = Chunk()

		chunk.write(.setUpvalue, line: 123)
		chunk.write(16, line: 123)

		#expect(instruction(from: chunk, metadata: ByteMetadata.self) == (
			line: 123,
			opcode: "OP_SET_UPVALUE",
			metadata: ByteMetadata(byte: 16),
			isSameLine: false,
			offset: 0,
			disassemblerOffset: 2
		))
	}

	@Test("Operators", arguments: [
		Opcode.equal,
		Opcode.greater,
		Opcode.less,
		Opcode.add,
		Opcode.subtract,
		Opcode.multiply,
		Opcode.divide,
		Opcode.not,
		Opcode.notEqual,
		Opcode.negate,
	]) func operators(_ opcode: Opcode) {
		var chunk = Chunk()

		chunk.write(opcode, line: 123)

		#expect(instruction(from: chunk) == (
			line: 123,
			opcode: opcode.description,
			isSameLine: false,
			offset: 0,
			disassemblerOffset: 1
		))
	}

	@Test("OP_CLOSURE") func closure() {
		var chunk = Chunk()
		var function = Function(arity: 0, chunk: Chunk(), name: "testin")
		function.upvalueCount = 1

		chunk.write(.closure, line: 123)

		let constant = chunk.make(constant: .function(function))
		chunk.write(constant, line: 123)
		chunk.write(Byte(0), line: 123)
		chunk.write(Byte(0), line: 123)

		let result = instruction(from: chunk, metadata: ClosureMetadata.self)

		#expect(result == (
			line: 123,
			opcode: "OP_CLOSURE",
			metadata: ClosureMetadata(
				function: function,
				upvalues: [Upvalue(isLocal: false, index: 0)],
				constant: constant
			),
			isSameLine: false,
			offset: 0,
			disassemblerOffset: 4
		))
	}
}
