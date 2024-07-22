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

		return compiler.compile()
	}

	@Test("Can compile add") func basic() throws {
		let module = compile("1 + 2")
		let result = LLVM.JIT().execute(module: module)
		#expect(result == 3)
	}
}
