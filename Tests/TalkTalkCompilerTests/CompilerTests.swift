//
//  CompilerTests.swift
//
//
//  Created by Pat Nakajima on 7/15/24.
//
import TalkTalkCompiler
import Testing

struct CompilerTests {
	@Test("Can compile add") func basic() throws {
		let compiler = Compiler(source: "1 + 2")
		let module = try compiler.compile()
		let result = LLVM.JIT().execute(module: module)
		#expect(result == 3)
	}

	@Test("Can compile subtract") func subtract() throws {
		let compiler = Compiler(source: "1 - 2")
		let module = try compiler.compile()
		let result = LLVM.JIT().execute(module: module)
		#expect(result == -1)
	}

	@Test("Can compile mult") func mult() throws {
		let compiler = Compiler(source: "2 * -3")
		let module = try compiler.compile()
		let result = LLVM.JIT().execute(module: module)
		#expect(result == -6)
	}

	@Test("Can compile lets") func lets() throws {
		let compiler = Compiler(source: """
		let foo = 2 + 3
		foo - 1
		""")
		let module = try compiler.compile()
		let result = LLVM.JIT().execute(module: module)
		#expect(result == 4)
	}
}
