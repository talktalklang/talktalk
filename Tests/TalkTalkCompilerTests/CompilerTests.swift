//
//  ABTCompilerTests.swift
//  
//
//  Created by Pat Nakajima on 7/21/24.
//

import TalkTalkCompiler
import Testing

struct CompilerTests {
	func compile(_ string: String) -> LLVM.Module {
		let compiler = Compiler(
			sourceFile: .init(path: "compiler.tlk", source: string)
		)

		return try! compiler.compile()
	}

	@Test("Can compile add") func basic() throws {
		let module = compile("1 + 2")
		let result = LLVM.JIT().execute(module: module)
		#expect(result == 3)
	}

	@Test("Can compile basic function call") func basicfn() throws {
		let module = compile("""
		func foo() {
			123
		}

		foo()
		""")
		let result = LLVM.JIT().execute(module: module)
		#expect(result == 123)
	}

	@Test("Can compile closures") func closures() throws {
		let module = compile("""
		// Test closures
		func makeCounter() {
			var i = 1

			func count() {
				i = i + 1
				return i
			}

			return count
		}

		var counter = makeCounter()
		counter()
		""")

		let result = LLVM.JIT().execute(module: module)
		module.dump()
		#expect(result == 2)
	}
}
