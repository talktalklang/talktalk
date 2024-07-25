//
//  CompilerTests.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

import Slips
import Testing

struct CompilerTests {
	@Test("Compiles literals") func literals() {
		#expect(Compiler("1").run() == .int(1))
		#expect(Compiler("(2)").run() == .int(2))
	}

	@Test("Compiles strings") func strings() {
		#expect(Compiler("'sup'").run() == .string("sup"))
		#expect(Compiler("('sup')").run() == .string("sup"))
	}

	@Test("Compiles add") func add() {
		#expect(Compiler("(+ 1 2)").run() == .int(3))
		#expect(Compiler("(+ 'fizz' 'buzz')").run() == .string("fizzbuzz"))
	}

	@Test("Compiles multiple") func multiple() {
		#expect(Compiler("""
		(def a 1)
		(def b 2)
		(+ a b)
		""").run() == .int(3))
	}

	@Test("Compiles if") func ifEval() {
		#expect(Compiler("""
		(if true (def a 1) (def b 2))
		a
		""").run() == .int(1))
	}

	@Test("Compiles functions") func functions() {
		#expect(Compiler("""
		(def addtwo (x in (+ x 2)))
		(addtwo 2)
		""").run() == .int(4))
	}
}
