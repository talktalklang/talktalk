//
//  InterpreterTests.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

import TalkTalk
import Testing

struct InterpreterTests {
	@Test("Evaluates literals") func literals() {
		#expect(Interpreter("1").evaluate() == .int(1))
		#expect(Interpreter("(2)").evaluate() == .int(2))
	}

	@Test("Evaluates add") func add() {
		#expect(Interpreter("1 + 2").evaluate() == .int(3))
	}

	@Test("Evaluates multiple") func multiple() {
		#expect(Interpreter("""
		a = 1
		b = 2
		a + b
		""").evaluate() == .int(3))
	}

	@Test("Evaluates if") func ifEval() {
		#expect(Interpreter("""
		if false { a = 1 } else { a = 2 }
		a
		""").evaluate() == .int(2))
	}

	@Test("Evaluates functions") func functions() {
		#expect(Interpreter("""
		addtwo = func(x) { x + 2 } 
		addtwo(3)
		""").evaluate() == .int(5))
	}

	@Test("Evaluates counter") func counter() {
		#expect(Interpreter("""
		makeCounter = func() {
			count = 0
			func() {
				count = count + 1
				count
			}
		}
		
		mycounter = makeCounter()
		mycounter()
		mycounter()
		mycounter()
		""").evaluate() == .int(3))
	}

	@Test("Doesn't mutate state between closures") func counter2() {
		#expect(Interpreter("""
		makeCounter = func() {
			count = 0
			func() {
				count = count + 1
				count
			}
		}
		
		mycounter = makeCounter()
		mycounter()
		mycounter()
		mycounter()

		urcounter = makeCounter()
		urcounter()
		""").evaluate() == .int(1))
	}
}
