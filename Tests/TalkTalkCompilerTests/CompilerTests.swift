//
//  CompilerTests.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

import TalkTalkCompiler
import TalkTalkAnalysis
import Testing

struct CompilerTests {
	@Test("Compiles literals") func literals() {
		#expect(Compiler("1").run() == .int(1))
		#expect(Compiler("(2)").run() == .int(2))
	}

	@Test("Compiles add") func add() {
		#expect(Compiler("1 + 2").run() == .int(3))
	}

	@Test("Compiles def") func def() {
		#expect(Compiler("""
		abc = 1 + 2
		abc
		""").run() == .int(3))
	}

	@Test("Compiles multiple") func multiple() {
		#expect(Compiler("""
		a = 1
		b = 2
		a + b
		""").run() == .int(3))
	}

	@Test("Compiles if") func ifEval() {
		#expect(Compiler("""
		if false {
			a = 1
		} else {
			a = 2
		}
		a
		""").run() == .int(2))
	}

	@Test("Compiles functions") func functions() {
		#expect(Compiler("""
		addtwo = func(x) {
			x + 2
		}
		addtwo(2)
		""").run() == .int(4))
	}

	@Test("Compiles counter") func counter() {
		#expect(Compiler("""
		makeCounter = func() {
			count = 0
			func() {
				count = count + 1
				count
			}
		}

		counter = makeCounter()
		counter()
		counter()
		""").run() == .int(2))
	}

	@Test("Compiles nested scopes") func nestedScopes() {
		#expect(Compiler("""
		addthis = func(x) {
			func(y) {
				x + y
			}
		}

		addfour = addthis(4)
		addfour(2)
		""").run() == .int(6))
	}
}
