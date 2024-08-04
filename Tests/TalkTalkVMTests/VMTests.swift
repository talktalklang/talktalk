//
//  VMTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/2/24.
//

import Testing
import TalkTalkVM
import TalkTalkBytecode

struct VMTests {
	func chunk(_ instructions: [Instruction]) -> Chunk {
		var chunk = Chunk(name: "main")
		for instruction in instructions {
			instruction.emit(into: &chunk)
		}

		return chunk.finalize()
	}

	@Test func int() {
		let chunk = chunk([
			Instruction(opcode: .constant, line: 1, offset: 0, metadata: .constant(.int(123)))
		])

		let result = VirtualMachine.run(chunk: chunk)
		#expect(result.get() == .int(123))
	}

	@Test func add() {
		let chunk = chunk([
			Instruction(opcode: .constant, line: 1, offset: 0, metadata: .constant(.int(10))),
			Instruction(opcode: .constant, line: 1, offset: 2, metadata: .constant(.int(20))),
			Instruction(opcode: .add, line: 1, offset: 4, metadata: .simple)
		])

		let result = VirtualMachine.run(chunk: chunk).get()
		#expect(result == .int(30))
	}

	@Test func subtract() {
		let chunk = chunk([
			Instruction(opcode: .constant, line: 1, offset: 2, metadata: .constant(.int(5))),
			Instruction(opcode: .constant, line: 1, offset: 0, metadata: .constant(.int(20))),
			Instruction(opcode: .subtract, line: 1, offset: 4, metadata: .simple)
		])

		let result = VirtualMachine.run(chunk: chunk)
		#expect(result.get() == .int(15))
	}

	@Test func divide() {
		let chunk = chunk([
			Instruction(opcode: .constant, line: 1, offset: 2, metadata: .constant(.int(10))),
			Instruction(opcode: .constant, line: 1, offset: 0, metadata: .constant(.int(20))),
			Instruction(opcode: .divide, line: 1, offset: 4, metadata: .simple)
		])

		let result = VirtualMachine.run(chunk: chunk)
		#expect(result.get() == .int(2))
	}

	@Test func multiply() {
		let chunk = chunk([
			Instruction(opcode: .constant, line: 1, offset: 2, metadata: .constant(.int(20))),
			Instruction(opcode: .constant, line: 1, offset: 0, metadata: .constant(.int(10))),
			Instruction(opcode: .multiply, line: 1, offset: 4, metadata: .simple)
		])

		let result = VirtualMachine.run(chunk: chunk)
		#expect(result.get() == .int(200))
	}
}
