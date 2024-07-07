//
//  CompilerTests.swift
//
//
//  Created by Pat Nakajima on 7/1/24.
//
@testable import TalkTalk
import Testing

final class TestOutput: OutputCollector {
	var debug = false

	init(debug: Bool = false) {
		self.debug = debug
	}

	func print(_ output: String, terminator: String) {
		if debug {
			Swift.print(output, terminator: terminator)
		}
		stdout.append(output)
		stdout.append(terminator)
	}

	func debug(_ output: String, terminator: String) {
		if debug {
			Swift.print(output, terminator: terminator)
		}
		debugOut.append(output)
		debugOut.append(terminator)
	}

	var stdout: String = ""
	var debugOut: String = ""
}

actor VMCompilerTests {
	@Test("Addition") func addition() {
		let output = TestOutput()
		#expect(VM.run(source: "print 1 + -2", output: output) == .ok)
		#expect(output.stdout == "-1\n")
	}

	@Test("Subtraction") func subtraction() {
		let output = TestOutput()
		#expect(VM.run(source: "print(123 - 3)", output: output) == .ok)
		#expect(output.stdout == "120\n")
	}

	@Test("Multiplication") func multiplication() {
		let output = TestOutput()
		#expect(VM.run(source: "print(5 * 5)", output: output) == .ok)
		#expect(output.stdout == "25\n")
	}

	@Test("Division") func dividing() {
		let output = TestOutput()
		#expect(VM.run(source: "print(25 / 5)", output: output) == .ok)
		#expect(output.stdout == "5\n")
	}

	@Test("Incessant terminators") func terminators() {
		let output = TestOutput()
		#expect(VM.run(source: """
		;;;
		;print(25 / 5);;;
		;;;;;;
		""", output: output) == .ok)
		#expect(output.stdout == "5\n")
	}

	@Test("Basic (with concurrency)") func basic() async {
		let count = await withTaskGroup(of: Void.self) { group in
			group.addTask {
				for _ in 0 ..< 100 {
					let output = TestOutput()
					let result = VM.run(source: "print(1 + -2)", output: output)
					#expect(result == .ok)
				}
			}

			var count = 0
			for await _ in group {
				count += 1
			}

			return count
		}

		#expect(count == 1)
	}

	@Test("Bools") func bools() {
		var output = TestOutput()
		#expect(VM.run(source: "print(true)", output: output) == .ok)
		#expect(output.stdout == "true\n")

		output = TestOutput()
		#expect(VM.run(source: "print(false)", output: output) == .ok)
		#expect(output.stdout == "false\n")
	}

	@Test("Negation") func negation() {
		let output = TestOutput()
		#expect(VM.run(source: "print(!false)", output: output) == .ok)
		#expect(output.stdout == "true\n")
	}

	@Test("Equality") func equality() {
		let output = TestOutput()
		#expect(VM.run(source: "print(2 == 2)", output: output) == .ok)
		#expect(output.stdout == "true\n")
	}

	@Test("Not equality") func notEquality() {
		let output = TestOutput()
		#expect(VM.run(source: "print(1 != 2)", output: output) == .ok)
		#expect(output.stdout == "true\n")
	}

	@Test("nil") func nill() {
		let output = TestOutput()
		#expect(VM.run(source: "print(nil)", output: output) == .ok)
		#expect(output.stdout == "nil\n")
	}

	@Test("Strings") func string() {
		let output = TestOutput()
		let source = """
		print("hello world")
		"""

		let result = VM.run(source: source, output: output)

		#expect(result == .ok)
		#expect(output.stdout == "hello world\n")
	}

	@Test("Global variables") func globals() {
		let output = TestOutput()
		let source = """
		var greeting = "hello world"
		print(greeting)
		"""

		#expect(VM.run(source: source, output: output) == .ok)
		#expect(output.stdout == "hello world\n")
	}

	@Test("Global variable reassignment") func globalReassignment() {
		let output = TestOutput()
		let source = """
		var greeting = "hello world"
		greeting = greeting + " SUP"
		print(greeting)
		"""

		#expect(VM.run(source: source, output: output) == .ok)
		#expect(output.stdout == "hello world SUP\n")
	}

	@Test("Assignment precedence") func assignmentPrecedence() {
		let output = TestOutput()
		let source = """
		var a = 1
		var b = 1
		var c = 1
		var d = 1

		print(a * b = c + d)
		"""

		#expect(VM.run(source: source, output: output) == .compileError)
		#expect(output.stdout.contains("Syntax Error"))
	}

	@Test("Local vars") func locals() {
		let output = TestOutput()
		let source = """
		{
			var a = "world"

			{
				var a = "hello"
				print(a)
			}

			print(a)
		}
		"""

		#expect(VM.run(source: source, output: output) == .ok)
		#expect(output.stdout == "hello\nworld\n")
	}

	@Test("Local variables with numbers") func localsWithNumbers() {
		let output = TestOutput()
		let source = """
		{
			var a = 1

			{
				var b = 2
				print(a + b)
			}

			print(a + 3)
		}
		"""

		#expect(VM.run(source: source, output: output) == .ok)
		#expect(output.stdout == "3\n4\n")
	}

	@Test("If statement") func ifStatement() {
		let output = TestOutput()
		let source = """
		if false {
			print("Dont show up")
		}

		if true {
			print("Do show up")
		}
		"""

		#expect(VM.run(source: source, output: output) == .ok)
		#expect(output.stdout == "Do show up\n")
	}

	@Test("Else statement") func elseStatement() {
		var output = TestOutput()
		var source = """
		if false {
			print("Dont show up")
		} else {
			print("Do show up")
		}
		"""

		#expect(VM.run(source: source, output: output) == .ok)
		#expect(output.stdout == "Do show up\n")

		output = TestOutput()
		source = """
		if true {
			print("Do show up")
		} else {
			print("Dont show up")
		}
		"""

		#expect(VM.run(source: source, output: output) == .ok)
		#expect(output.stdout == "Do show up\n")
	}

	@Test("&&") func and() {
		var output = TestOutput()
		#expect(VM.run(source: "print(true && false)", output: output) == .ok)
		#expect(output.stdout == "false\n")

		output = TestOutput()
		#expect(VM.run(source: "print(true && true)", output: output) == .ok)
		#expect(output.stdout == "true\n")
	}

	@Test("||") func or() {
		// TODO: Actually test the evaluation
		var output = TestOutput()
		#expect(VM.run(source: """
		var a = 1
		if a > 2 || true {
			print("cool")
		}
		""", output: output) == .ok)
		#expect(output.stdout == "cool\n")

		output = TestOutput()
		#expect(VM.run(source: """
		if false || false {
			print("cool")
		}
		""", output: output) == .ok)
		#expect(output.stdout == "")
	}

	@Test("while loop") func whileLoop() {
		let output = TestOutput()
		let source = """
		var a = 0
		while a < 3 {
			a = a + 1
			print(a)
		}
		"""

		#expect(VM.run(source: source, output: output) == .ok)
		#expect(output.stdout == "1\n2\n3\n")
	}

	@Test("Function") func function() {
		let output = TestOutput()
		let source = """
		func greet() {
			print("sup")
		}

		greet();
		"""

		#expect(VM.run(source: source, output: output) == .ok)
		#expect(output.stdout == "sup\n")
	}

	@Test("Function (this wasnt working?)") func function2() {
		let output = TestOutput()
		let source = """
		func foo() {
			return "bar"
		}

		print(foo())
		"""

		#expect(VM.run(source: source, output: output) == .ok)
		#expect(output.stdout == "bar\n")
	}

	@Test("Function (this wasnt working either)") func function3() {
		let output = TestOutput()
		let source = """
		func foo() {
			return "bar"
		}

		var a = foo()

		print(a)
		"""

		#expect(VM.run(source: source, output: output) == .ok)
		#expect(output.stdout == "bar\n")
	}

	@Test("Function Returns") func functionReturns() {
		let output = TestOutput()
		let source = """
		func greet(name) {
			return "sup, " + name

			print("don't show up.")
		}

		print(greet("pat"))
		"""

		#expect(VM.run(source: source, output: output) == .ok)
		#expect(output.stdout == "sup, pat\n")
	}

	@Test("Nested function returns") func nestedFunctionReturns() {
		let output = TestOutput()
		let source = """
		func outer() {
			func inner(name) {
				return name
			}

			return inner("pat")
		}

		print outer()
		"""

		#expect(VM.run(source: source, output: output) == .ok)
		#expect(output.stdout == "pat\n")
	}

	@Test("Top level returns are a no no") func topLevelReturns() {
		let output = TestOutput()
		let source = """
		return "nope"
		"""

		#expect(VM.run(source: source, output: output) == .compileError)
	}

	@Test("Native print") func nativePrint() {
		let output = TestOutput()
		let source = """
		var msg = "yup"
		print(msg)
		"""

		#expect(VM.run(source: source, output: output) == .ok)
		#expect(output.stdout == "yup\n")
	}

	@Test("Closure") func closure() {
		let output = TestOutput()
		let source = """
		func outer() {
			var x = "outside"
			func inner() {
				print(x)
			}
			inner()
		}
		outer()
		"""

		#expect(VM.run(source: source, output: output) == .ok)
		#expect(output.stdout == "outside\n")
	}

	@Test("Trickier closure") func trickierClosure() {
		let output = TestOutput()
		let source = """
		func outer() {
			var x = "value"
			func middle() {
				func inner() {
					print(x)
				}

				print "create inner closure"
				return inner
			}

			print "return from outer"
			return middle
		}

		var mid = outer()
		var in = mid()
		in()
		"""

		#expect(VM.run(source: source, output: output) == .ok)
		#expect(output.stdout == """
		return from outer
		create inner closure
		value

		""")
	}

	@Test("Counter example") func counter() {
		let source = """
		func makeCounter() {
			var i = 0

			func count() {
				i = i + 1
				print i
			}

			return count
		}

		var counter = makeCounter()
		counter()
		counter()
		"""

		let output = TestOutput()

		#expect(VM.run(source: source, output: output) == .ok)
		#expect(output.stdout == "1\n2\n")
	}

	@Test("Simple class") func simpleClass() {
		let source = """
		class Person {}

		print(Person)
		"""

		let output = TestOutput()

		#expect(VM.run(source: source, output: output) == .ok)
		#expect(output.stdout == "<class Person>\n")
	}

	@Test("Simple Instance") func simpleInstance() {
		let source = """
		class Person {}

		print(Person())
		"""

		let output = TestOutput()

		#expect(VM.run(source: source, output: output) == .ok)
		#expect(output.stdout == "<Person instance>\n")
	}

	@Test("Simple get/set property") func getset() {
		let source = """
		class Person {}

		var person = Person()
		person.name = "Pat"

		print(person.name)
		"""

		let output = TestOutput()

		#expect(VM.run(source: source, output: output) == .ok)
		#expect(output.stdout == "Pat\n")
	}

	@Test("Simple method") func simpleMethod() {
		let source = """
		class Person {
			func greet() {
				print("sup")
			}
		}

		Person().greet()
		"""

		let output = TestOutput()

		#expect(VM.run(source: source, output: output) == .ok)
		#expect(output.stdout == "sup\n")
	}

	@Test("Top level self is a no no") func topLevelSelf() {
		let output = TestOutput()

		#expect(VM.run(source: "self", output: output) == .compileError)
	}

	@Test("Bound method") func boundMethod() {
		let source = """
		class Person {
			func greet() {
				print(self.name)
			}
		}

		var person = Person()
		person.name = "sup"
		person.greet()
		"""

		let output = TestOutput()

//		#expect(VM.run(source: source, output: output) == .ok)
		#expect(output.stdout == "sup\n")
	}
}
