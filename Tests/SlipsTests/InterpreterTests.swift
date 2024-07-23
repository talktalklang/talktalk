//
//  InterpreterTests.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

import Slips
import Testing

struct InterpreterTests {
	@Test("Evaluates literals") func literals() {
		#expect(Interpreter("1").evaluate() == .int(1))
		#expect(Interpreter("(2)").evaluate() == .int(2))
	}

	@Test("Evaluates strings") func strings() {
		#expect(Interpreter("'sup'").evaluate() == .string("sup"))
		#expect(Interpreter("('sup')").evaluate() == .string("sup"))
	}

	@Test("Evaluates add") func add() {
		#expect(Interpreter("(+ 1 2)").evaluate() == .int(3))
		#expect(Interpreter("(+ 'fizz' 'buzz')").evaluate() == .string("fizzbuzz"))
	}

	@Test("Evaluates multiple") func multiple() {
		#expect(Interpreter("""
		(def a 1)
		(def b 2)
		(+ a b)
		""").evaluate() == .int(3))
	}

	@Test("Evaluates if") func ifEval() {
		#expect(Interpreter("""
		(def a 1)
		(def b 2)
		(if true a b)
		""").evaluate() == .int(1))
	}
}
