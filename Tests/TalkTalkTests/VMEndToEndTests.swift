//
//  VMEndToEndTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/2/24.
//

import TalkTalkAnalysis
import TalkTalkBytecode
import TalkTalkCompiler
import TalkTalkSyntax
import TalkTalkVM
import Testing

actor VMEndToEndTests {
	func compile(_ string: String) throws -> Chunk {
		let parsed = Parser.parse(string)
		let analyzed = try! Analyzer.analyzedExprs(parsed)
		var compiler = Compiler(analyzedExprs: analyzed)
		return try compiler.compile()
	}

	func run(_ string: String) -> TalkTalkBytecode.Value {
		let chunk = try! compile(string)
		return VirtualMachine.run(chunk: chunk).get()
	}

	@Test("Adds") func adds() {
		#expect(run("1 + 2") == .int(3))
	}

	@Test("Subtracts") func subtracts() {
		#expect(run("2 - 1") == .int(1))
	}

	@Test("Comparison") func comparison() {
		#expect(run("1 == 2") == .bool(false))
		#expect(run("2 == 2") == .bool(true))

		#expect(run("1 != 2") == .bool(true))
		#expect(run("2 != 2") == .bool(false))

		#expect(run("1 < 2") == .bool(true))
		#expect(run("2 < 1") == .bool(false))

		#expect(run("1 > 2") == .bool(false))
		#expect(run("2 > 1") == .bool(true))

		#expect(run("1 <= 2") == .bool(true))
		#expect(run("2 <= 1") == .bool(false))
		#expect(run("2 <= 2") == .bool(true))

		#expect(run("1 >= 2") == .bool(false))
		#expect(run("2 >= 1") == .bool(true))
		#expect(run("2 >= 2") == .bool(true))
	}

	@Test("Negate") func negate() {
		#expect(run("-123") == .int(-123))
		#expect(run("--123") == .int(123))
	}

	@Test("Not") func not() {
		#expect(run("!true") == .bool(false))
		#expect(run("!false") == .bool(true))
	}

	@Test("Strings") func strings() {
		#expect(run(#""hello world""#) == .data(0))
	}

	@Test("If expr") func ifExpr() {
		#expect(run("""
		if false {
			123
		} else {
			456
		}
		""") == .int(456))
	}

	@Test("Var expr") func varExpr() {
		#expect(run("""
		a = 10
		b = 20
		a = a + b
		a
		""") == .int(30))
	}

	@Test("Basic func/call expr") func funcExpr() {
		#expect(run("""
		i = func() {
			123
		}()

		i + 1
		""") == .int(124))
	}

	@Test("Func arguments") func funcArgs() {
		#expect(run("""
		func(i) {
			i + 20
		}(10)
		""") == .int(30))
	}

	@Test("Get var from enlosing scope") func enclosing() {
		#expect(run("""
		a10 = 10
		b20 = 20
		func() {
			c30 = 30
			a10 + b20 + c30
		}()
		""") == .int(60))
	}

	@Test("Modify var from enclosing scope") func modifyEnclosing() {
		#expect(run("""
		a = 10
		func() {
			a = 20
		}()
		a
		""") == .int(10))
	}

	@Test("Works with counter") func counter() {
		#expect(run("""
		func makeCounter() {
			count = 0
			func increment() {
				count = count + 1
				count
			}
			increment
		}

		mycounter = makeCounter()
		mycounter()
		mycounter()
		""") == .int(2))
	}

	@Test("Doesn't leak out of closures") func closureLeak() throws {
		#expect(throws: CompilerError.self) {
			try compile("""
			func() {
			 a = 123
			}

			a
			""")
		}
	}
}
