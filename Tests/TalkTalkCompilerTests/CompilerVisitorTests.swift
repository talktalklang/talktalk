//
//  CompilerVisitorTests.swift
//
//
//  Created by Pat Nakajima on 7/17/24.
//
import C_LLVM
@testable import TalkTalkCompiler
import TalkTalkSyntax
import TalkTalkTyper
import Testing

struct CompilerVisitorTests {
	var builder: LLVM.Builder
	var module: LLVM.Module

	init() {
		self.module = LLVM.Module(in: .global)
		self.builder = LLVM.Builder(module: module)
	}

	@Test("Int literal IR") func intLiteral() throws {
		let node: IntLiteralSyntax = Parser.parse(expr: "123")!
		let visitor = CompilerVisitor(bindings: Typer(ast: node).check(), builder: builder, module: module)

		let result = try #require(visitor.visit(node, context: module)).as(LLVM.IntValue.self)!
		#expect(result == .i32(123))
	}

	@Test("Add IR") func add() throws {
		let node: BinaryExprSyntax = Parser.parse(expr: "1 + 2")!
		let visitor = CompilerVisitor(bindings: Typer(ast: node).check(), builder: builder, module: module)

		let result: any LLVM.IRValue = try #require(visitor.visit(node, context: module)).unwrap()
		let string = String(cString: LLVMPrintValueToString(result.ref))
		#expect(string == "i32 3")
	}

	@Test("Sub IR") func sub() throws {
		let node: BinaryExprSyntax = Parser.parse(expr: "1 - 2")!
		let visitor = CompilerVisitor(bindings: Typer(ast: node).check(), builder: builder, module: module)

		let result: any LLVM.IRValue = try #require(visitor.visit(node, context: module)).unwrap()

		let string = String(cString: LLVMPrintValueToString(result.ref))
		#expect(string == "i32 -1")
	}

	@Test("let Stmt IR") func letstmt() throws {
		let node = Parser.parse(statement: """
		let foo = 123
		""")!

		let visitor = CompilerVisitor(bindings: Typer(ast: node).check(), builder: builder, module: module)
		let result = try #require(visitor.visit(node, context: module))

		#expect(visitor.currentFunction.locals["foo"] == .defined(LLVM.IntValue.i32(123)))
		#expect(result == .void())
	}

	@Test("function IR") func function() throws {
		let node = Parser.parse(decl: """
		func foo(i) -> Int {
			return i * 2
		}
		""")!

		let visitor = CompilerVisitor(bindings: Typer(ast: node).check(), builder: builder, module: module)
		let result: any LLVM.IRValue = try #require(visitor.visit(node, context: module)).unwrap()

		let string = String(cString: LLVMPrintValueToString(result.ref))

		#expect(string == """
		define i32 @foo(i32 %0) {
		entry:
		  %1 = mul i32 %0, 2
		  ret i32 %1
		}

		""")
	}

	@Test("Captures") func captures() throws {
		let source = """
		var i = 1
		func foo() -> Int {
			return i * 2
		}
		"""
		let node = Parser.parse(file: .init(path: "captures", source: source))

		print(node.description)

		let bindings = Typer(ast: node).check()
		for error in bindings.errors {
			error.report(in: .init(path: "", source: """
			var i = 1
			func foo() -> Int {
				return i * 2
			}
			"""))
		}

		let def = bindings.typedef(at: 16)

		let visitor = CompilerVisitor(bindings: bindings, builder: builder, module: module)
		_ = visitor.visit(node, context: module)

		let string = String(cString: LLVMPrintModuleToString(module.ref))

		#expect(string == """
		define i32 @foo(i32 %0) {
		entry:
			%1 = mul i32 %0, 2
			ret i32 %1
		}

		""")
	}
}
