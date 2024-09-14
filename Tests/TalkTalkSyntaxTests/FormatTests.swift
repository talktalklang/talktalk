//
//  FormatTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/13/24.
//

import Testing
import TalkTalkSyntax

struct FormatTests {
	func format(_ input: SourceFile, width: Int = 80) -> String {
		try! Formatter(input: input).format(width: width)
	}

	@Test("Basic binary op") func binaryOp() throws {
		let formatted = format("""
		1+   2
		""")

		#expect(formatted == "1 + 2")
	}

	@Test("Repects newlines at top line") func respectsNewlines() throws {
		let a = format("""
		print("foo")
		print("bar")
		""")

		#expect(a == """
		print("foo")
		print("bar")
		""")

		let b = format("""
		print("foo")

		print("bar")
		""")

		#expect(b == """
		print("foo")

		print("bar")
		""")

		let c = format("""
		print("foo")


		print("bar")
		""")

		// Make sure it collapses a bunch of newlines
		#expect(c == """
		print("foo")

		print("bar")
		""")
	}

	@Test("Basic func") func basicFunc() throws {
		let formatted = format("""
		func foo(
			) {
		"bar" }
		""")

		#expect(formatted == """
		func foo() { "bar" }
		""")

		let twoStmts = format("""
		func foo(
			) {
		"bar" 
				"fizz"}
		""")

		#expect(twoStmts == """
		func foo() {
			"bar"
			"fizz"
		}
		""")

		let narrow = format("""
		func foo(
			) {
		"bar" }
		""", width: 5)

		#expect(narrow == """
		func foo() {
			"bar"
		}
		""")
	}

	@Test("Nested functions") func nestedFuncs() throws {
		let formatted = format("""
		func foo(
			) {
		func bar() { "fizz" } }
		""")

		#expect(formatted == """
		func foo() {
			func bar() { "fizz" }
		}
		""")
	}

	@Test("Basic call") func call() throws {
		let formatted = format("""
		foo(
			1 ,   2, 
				3
				)
		""")

		#expect(formatted == """
		foo(1, 2, 3)
		""")

		let narrow = format("""
		foo(
			1 ,   2, 
				3
				)
		""", width: 4)

		#expect(narrow == """
		foo(
			1,
			2,
			3
		)
		""")
	}

	@Test("Basic array") func basicArray() throws {
		let formatted = format("""
		[1,2,  3,4
		]
		""")

		#expect(formatted == """
		[1, 2, 3, 4]
		""")

		let narrow = format("""
		[1,2,  3,4
		]
		""", width: 5)

		#expect(narrow == """
		[
			1,
			2,
			3,
			4
		]
		""")
	}

	@Test("Basic struct") func basicStruct() throws {
		let formatted = format("""
		struct  Foo<
			Fizz> {
			var bar:   String

				init() {}

				func foo(  ) { 
		print( 
				"sup")


			print("yoyo")
				}
		}
		""")

		#expect(formatted == """
		struct Foo<Fizz> {
			var bar: String

			init() {}

			func foo() {
				print("sup")

				print("yoyo")
			}
		}
		""")
	}

	@Test("Fib") func fib() throws {
		let formatted = format(
			"""
			func fib(n) {
				if (n <= 1) {
					return n
				}

				return fib(n - 2) + fib(n - 1)
			}

			var i = 0
			while i < 35 {
				print(fib(i))
				i = i + 1
			}
			"""
		)

		#expect(formatted == """
		func fib(n) {
			if (n <= 1) {
				return n
			}

			return fib(n - 2) + fib(n - 1)
		}

		var i = 0
		while i < 35 {
			print(fib(i))
			i = i + 1
		}
		""")
	}
}
