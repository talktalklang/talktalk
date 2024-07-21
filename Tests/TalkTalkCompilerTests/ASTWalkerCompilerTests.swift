//
//  CompilerTests.swift
//
//
//  Created by Pat Nakajima on 7/15/24.
//
import TalkTalkCompiler
import Testing

struct ASTWalkerCompilerTests {
	@Test("Can compile add") func basic() throws {
		let compiler = ASTCompiler(filename: "compiler", source: "1 + 2")
		let module = try compiler.compile()
		let result = LLVM.JIT().execute(module: module)
		#expect(result == 3)
	}

	@Test("Can compile subtract") func subtract() throws {
		let compiler = ASTCompiler(filename: "compiler", source: "1 - 2")
		let module = try compiler.compile()
		let result = LLVM.JIT().execute(module: module)
		#expect(result == -1)
	}

	@Test("Can compile mult") func mult() throws {
		let compiler = ASTCompiler(filename: "compiler", source: "2 * -3")
		let module = try compiler.compile()
		let result = LLVM.JIT().execute(module: module)
		#expect(result == -6)
	}

	@Test("Can compile lets") func lets() throws {
		let compiler = ASTCompiler(filename: "compiler", source: """
		let foo = 2 + 3
		foo - 1
		""")
		let module = try compiler.compile()
		let result = LLVM.JIT().execute(module: module)
		#expect(result == 4)
	}

	@Test("Can compile functions") func funcs() throws {
		let compiler = ASTCompiler(filename: "compiler", source: """
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
		let compiler = ASTCompiler(filename: "compiler", source: """
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
		let compiler = ASTCompiler(filename: "compiler", source: """
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
		let compiler = ASTCompiler(filename: "compiler", source: """
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
		let compiler = ASTCompiler(filename: "compiler", source: """
		var i = 0
		while i < 5 {
			i = i + 1
		}

		i
		""")

		let module = try compiler.compile()
		let result = LLVM.JIT().execute(module: module)
		#expect(result == 5)
	}

	@Test("can compile with proper scopes") func scopes() throws {
		let compiler = ASTCompiler(filename: "compiler", source: """
		var i = 123

		func foo() {
			var i = 345
			return i
		}

		i
		""")

		let module = try compiler.compile()
		let result = LLVM.JIT().execute(module: module)
		#expect(result == 123)
	}

	@Test("can compile fib") func fib() throws {
		let compiler = ASTCompiler(filename: "compiler", source: """
		func fib(n) {
			if n <= 1 { return n }
			return fib(n - 2) + fib(n - 1)
		}

		var i = 0
		var o = 0
		while i < 10 {
			o = fib(i)
			i = i + 1
		}

		o
		""")

		let module = try compiler.compile()
		let result = LLVM.JIT().execute(module: module)
		#expect(result == 34)
	}

	@Test("can compile fib (optimized)") func fibO() throws {
		let compiler = ASTCompiler(filename: "compiler", source: """
		func fib(n) {
			if n <= 1 { return n }
			return fib(n - 2) + fib(n - 1)
		}

		var i = 0
		var o = 0
		while i < 10 {
			o = fib(i)
			i = i + 1
		}

		o
		""")

		let module = try compiler.compile(optimize: true)
		let result = LLVM.JIT().execute(module: module)
		#expect(result == 34)
	}

	@Test("can compile closures") func closures() throws {
		let compiler = ASTCompiler(filename: "compiler", source: """
		// Test closures
		func makeCounter() {
			var i = 0

			func count() {
				i = i + 1
				i
			}

			return count
		}

		var counter = makeCounter()
		counter()
		counter()
		""")

		let module = try compiler.compile(optimize: true)
		let result = LLVM.JIT().execute(module: module)
		#expect(result == 2)
	}
}
