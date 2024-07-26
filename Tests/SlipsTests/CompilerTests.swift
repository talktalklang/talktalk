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

	@Test("Compiles add") func add() {
		#expect(Compiler("(+ 1 2)").run() == .int(3))
	}

	@Test("Compiles def") func def() {
		#expect(Compiler("""
		(def abc (+ 1 2))
		abc
		""").run() == .int(3))
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

	@Test("Compiles calls") func calls() {
		#expect(Compiler("""
		(call (x in (+ x 2)) 2)
		""").run() == .int(4))
	}

	@Test("Evaluates nested scopes") func nestedScopes() {
		#expect(Compiler("""
		(
			def addthis (x in
				(y in
					(+ y x)
				)
			)
		)
		(def addfour (addthis 8))
		(call addfour 2)
		""").run() == .int(10))
	}
}
