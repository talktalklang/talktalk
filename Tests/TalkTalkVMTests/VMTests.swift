//
//  VMTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/2/24.
//

import Testing
import TalkTalkVM
import TalkTalkCompiler
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
			Instruction(opcode: .constant, offset: 0, line: 1, metadata: .constant(.int(123)))
		])

		let result = VirtualMachine.run(module: .main(chunk))
		#expect(result.get() == .int(123))
	}

	@Test func add() {
		let chunk = chunk([
			Instruction(opcode: .constant, offset: 0, line: 1, metadata: .constant(.int(10))),
			Instruction(opcode: .constant, offset: 2, line: 1, metadata: .constant(.int(20))),
			Instruction(opcode: .add, offset: 4, line: 1, metadata: .simple)
		])

		let result = VirtualMachine.run(module: .main(chunk)).get()
		#expect(result == .int(30))
	}

	@Test func subtract() {
		let chunk = chunk([
			Instruction(opcode: .constant, offset: 2, line: 1, metadata: .constant(.int(5))),
			Instruction(opcode: .constant, offset: 0, line: 1, metadata: .constant(.int(20))),
			Instruction(opcode: .subtract, offset: 4, line: 1, metadata: .simple)
		])

		let result = VirtualMachine.run(module: .main(chunk))
		#expect(result.get() == .int(15))
	}

	@Test func divide() {
		let chunk = chunk([
			Instruction(opcode: .constant, offset: 2, line: 1, metadata: .constant(.int(10))),
			Instruction(opcode: .constant, offset: 0, line: 1, metadata: .constant(.int(20))),
			Instruction(opcode: .divide, offset: 4, line: 1, metadata: .simple)
		])

		let result = VirtualMachine.run(module: .main(chunk))
		#expect(result.get() == .int(2))
	}

	@Test func multiply() {
		let chunk = chunk([
			Instruction(opcode: .constant, offset: 2, line: 1, metadata: .constant(.int(20))),
			Instruction(opcode: .constant, offset: 0, line: 1, metadata: .constant(.int(10))),
			Instruction(opcode: .multiply, offset: 4, line: 1, metadata: .simple)
		])

		let result = VirtualMachine.run(module: .main(chunk))
		#expect(result.get() == .int(200))
	}
}
