//
//  VMTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/2/24.
//

import TalkTalkBytecode
import TalkTalkCompiler
import TalkTalkVM
import Testing

@MainActor
struct VMTests {
	func chunk(_ instructions: [Instruction]) -> Chunk {
		var chunk = Chunk(name: "main", symbol: .function("VMTests", "main", []), path: "test")
		for instruction in instructions {
			instruction.emit(into: &chunk)
		}

		return chunk.finalize()
	}

	@Test func int() throws {
		let chunk = chunk([
			Instruction(path: "", opcode: .constant, offset: 0, line: 1, metadata: .constant(.int(123))),
		])

		let result = VirtualMachine.run(module: .main(.init(chunk: chunk)))
		#expect(try result.get() == .int(123))
	}

	@Test func add() throws {
		let chunk = chunk([
			Instruction(path: "", opcode: .constant, offset: 0, line: 1, metadata: .constant(.int(10))),
			Instruction(path: "", opcode: .constant, offset: 2, line: 1, metadata: .constant(.int(20))),
			Instruction(path: "", opcode: .add, offset: 4, line: 1, metadata: .simple),
		])

		let result = try VirtualMachine.run(module: .main(.init(chunk: chunk))).get()
		#expect(result == .int(30))
	}

	@Test func subtract() throws {
		let chunk = chunk([
			Instruction(path: "", opcode: .constant, offset: 2, line: 1, metadata: .constant(.int(5))),
			Instruction(path: "", opcode: .constant, offset: 0, line: 1, metadata: .constant(.int(20))),
			Instruction(path: "", opcode: .subtract, offset: 4, line: 1, metadata: .simple),
		])

		let result = VirtualMachine.run(module: .main(.init(chunk: chunk)))
		#expect(try result.get() == .int(15))
	}

	@Test func divide() throws {
		let chunk = chunk([
			Instruction(path: "", opcode: .constant, offset: 2, line: 1, metadata: .constant(.int(10))),
			Instruction(path: "", opcode: .constant, offset: 0, line: 1, metadata: .constant(.int(20))),
			Instruction(path: "", opcode: .divide, offset: 4, line: 1, metadata: .simple),
		])

		let result = VirtualMachine.run(module: .main(.init(chunk: chunk)))
		#expect(try result.get() == .int(2))
	}

	@Test func multiply() throws {
		let chunk = chunk([
			Instruction(path: "", opcode: .constant, offset: 2, line: 1, metadata: .constant(.int(20))),
			Instruction(path: "", opcode: .constant, offset: 0, line: 1, metadata: .constant(.int(10))),
			Instruction(path: "", opcode: .multiply, offset: 4, line: 1, metadata: .simple),
		])

		let result = VirtualMachine.run(module: .main(.init(chunk: chunk)))
		#expect(try result.get() == .int(200))
	}
}
