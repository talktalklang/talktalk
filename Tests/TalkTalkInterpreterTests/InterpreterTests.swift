//
//  InterpreterTests.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

import TalkTalkInterpreter
import Testing

@MainActor
struct InterpreterTests {
	@Test("Evaluates literals") func literals() {
		try! #expect(Interpreter("1").evaluate() == .int(1))
		try! #expect(Interpreter("(2)").evaluate() == .int(2))
	}

	@Test("Evaluates add") func add() {
		try! #expect(Interpreter("1 + 2").evaluate() == .int(3))
	}

	@Test("Evaluates comparison") func comparison() {
		try! #expect(Interpreter("1 < 2").evaluate() == .bool(true))
		try! #expect(Interpreter("1 > 2").evaluate() == .bool(false))
	}

	@Test("Evaluates multiple") func multiple() {
		try! #expect(Interpreter("""
		a = 1
		b = 2
		a + b
		""").evaluate() == .int(3))
	}

	@Test("Evaluates equality") func equality() {
		try! #expect(Interpreter("""
		1 == 2
		""").evaluate() == .bool(false))
	}

	@Test("Evaluates not equal") func notEqual() {
		try! #expect(Interpreter("""
		1 != 2
		""").evaluate() == .bool(true))
	}

	@Test("Evaluates if") func ifEval() {
		try! #expect(Interpreter("""
		let a
		if false { a = 1 } else { a = 2 }
		a
		""").evaluate() == .int(2))
	}

	@Test("Evaluates while") func whileEval() {
		try! #expect(Interpreter("""
		var a = 0
		while a != 4 {
			a = a + 1
		}
		a
		""").evaluate() == .int(4))
	}

	@Test("Evaluates functions") func functions() {
		try! #expect(Interpreter("""
		let addtwo = func(x) { x + 2 } 
		addtwo(3)
		""").evaluate() == .int(5))
	}

	@Test("Evaluates return") func returns() {
		try! #expect(Interpreter("""
		func foo() {
			return 5
			1
		}

		foo()
		""").evaluate() == .int(5))
	}

	@Test("Evaluates counter") func counter() {
		try! #expect(Interpreter("""
		func makeCounter() {
			var count = 0
			func() {
				count = count + 1
				return count
			}
		}

		let mycounter = makeCounter()
		mycounter()
		mycounter()
		mycounter()
		""").evaluate() == .int(3))
	}

	@Test("Doesn't mutate state between closures") func counter2() {
		try! #expect(Interpreter("""
		let makeCounter = func() {
			count = 0
			func() {
				count = count + 1
				count
			}
		}

		let mycounter = makeCounter()
		mycounter()
		mycounter()
		mycounter()

		let urcounter = makeCounter()
		urcounter()
		""").evaluate() == .int(1))
	}

	@Test("Evaluates fib") func fib() {
		_ = try! Interpreter("""
			func fib(n) {
				if (n <= 1) { return n } else { }
				return fib(n - 2) + fib(n - 1)
			}

			let i = 0
			while i < 5 {
				print(fib(i))
				i = i + 1
			}
			"""
		).evaluate()
	}

	@Test("Evaluates Struct properties") func structs() {
		try! #expect(Interpreter("""
		struct Foo {
			let age: i32
		}

		let foo = Foo(age: 123)
		foo.age
		""").evaluate() == .int(123))
	}

	@Test("Evaluates Struct methods") func structsMethods() {
		try! #expect(Interpreter("""
		struct Foo {
			let age: i32

			func add() {
				age + 3
			}
		}

		let foo = Foo(age: 123)
		foo.add()
		""").evaluate() == .int(126))
	}

	@Test("Evaluates Struct methods with args") func structsMethodsArgs() {
		try! #expect(Interpreter("""
		struct Foo {
			let age: i32

			func add(i) {
				age + 3 + i
			}
		}

		let foo = Foo(age: 123)
		foo.add(3)
		""").evaluate() == .int(129))
	}
}
