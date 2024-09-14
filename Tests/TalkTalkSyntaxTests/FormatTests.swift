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
}
