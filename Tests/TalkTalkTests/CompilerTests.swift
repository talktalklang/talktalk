//
//  CompilerTests.swift
//  
//
//  Created by Pat Nakajima on 7/1/24.
//
@testable import TalkTalk
import Testing

struct CompilerTests {
	@Test("Basic") func basic() {
		let source = "1 + 2"
		var compiler = Compiler(source: source)
		compiler.compile()

		
		var vm = VM(chunk: compiler.compilingChunk)
		#expect(vm.run() == .ok)
	}
}
