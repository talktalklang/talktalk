//
//  CompilerTests.swift
//
//
//  Created by Pat Nakajima on 7/15/24.
//
import TalkTalkCompiler
import Testing

struct CompilerTests {
	@Test("Can compile add") func basic() throws {
		let compiler = Compiler(source: "1 + 2")
		let module = try compiler.compile()
		let result = LLVM.JIT().execute(module: module)
		#expect(result == 3)
	}

	@Test("Can compile subtract") func subtract() throws {
		let compiler = Compiler(source: "1 - 2")
		let module = try compiler.compile()
		let result = LLVM.JIT().execute(module: module)
		#expect(result == -1)
	}

	@Test("Can compile mult") func mult() throws {
		let compiler = Compiler(source: "2 * -3")
		let module = try compiler.compile()
		let result = LLVM.JIT().execute(module: module)
		#expect(result == -6)
	}

	@Test("Can compile lets") func lets() throws {
		let compiler = Compiler(source: """
		let foo = 2 + 3
		foo - 1
		""")
		let module = try compiler.compile()
		let result = LLVM.JIT().execute(module: module)
		#expect(result == 4)
	}

	@Test("Can compile functions") func funcs() throws {
		let compiler = Compiler(source: """
		func foo(i) {
			return i * 2
		}

		foo(3) + foo(2)
		""")
		let module = try compiler.compile()
		let result = LLVM.JIT().execute(module: module)
		#expect(result == 10)
	}

	@Test("Can compile conditionals") func conds() throws {
		let compiler = Compiler(source: """
		func foo() {
			if false {
				return 123
			} else {
				return 456
			}
		}

		foo()
		""")

		let module = try compiler.compile()
		let result = LLVM.JIT().execute(module: module)
		#expect(result == 456)
	}

	@Test("Can compile if exprs") func ifExpr() throws {
		let compiler = Compiler(source: """
		let val = if true {
			123
		} else {
			456
		}

		val
		""")

		let module = try compiler.compile()
		let result = LLVM.JIT().execute(module: module)
		#expect(result == 123)
	}

	@Test("Can compile variables") func vars() throws {
		let compiler = Compiler(source: """
		var i = 1
		i = 1 + i
		i = 1 + i
		i
		""")

		let module = try compiler.compile()
		let result = LLVM.JIT().execute(module: module)
		#expect(result == 3)
	}

	@Test("Can compile while loop") func whileLoop() throws {
		let compiler = Compiler(source: """
		var i = 0
		while i < 5 {
			i = i + 1
		}

		i
		""")

		let module = try compiler.compile()
		let result = LLVM.JIT().execute(module: module)
		#expect(result == 4)
	}

	@Test("can compile fib", .disabled()) func fib() throws {
		_ = """
		func fib(n) {
			if n <= 1 { return n }
			return fib(n - 2) + fib(n - 1)
		}

		var i = 0
		while i < 35 {
			print(fib(i))
			i = i + 1
		}
		"""

		#expect(Bool(false), "not here yet")
	}
}
