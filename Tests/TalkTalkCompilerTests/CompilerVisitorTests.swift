//
//  CompilerVisitorTests.swift
//  
//
//  Created by Pat Nakajima on 7/17/24.
//
import C_LLVM
import Testing
import TalkTalkSyntax
@testable import TalkTalkCompiler

struct CompilerVisitorTests {
	var builder: LLVM.Builder
	var module: LLVM.Module

	init() {
		self.module = LLVM.Module(in: .global)
		self.builder = LLVM.Builder(module: self.module)
	}

	@Test("Int literal IR") func intLiteral() throws {
		let node: IntLiteralSyntax = Parser.parse(expr: "123")!
		let visitor = CompilerVisitor(builder: builder, module: module)

		let result = try #require(visitor.visit(node, context: module)).as(LLVM.IntValue.self)!
		#expect(result == .i32(123))
	}

	@Test("Add IR") func add() throws {
		let node: BinaryExprSyntax = Parser.parse(expr: "1 + 2")!
		let visitor = CompilerVisitor(builder: builder, module: module)

		let result = try #require(visitor.visit(node, context: module))

//		#expect(result.opcode == LLVMAdd)
//		#expect(result.lhs as! LLVM.IntValue == .i32(1))
//		#expect(result.rhs as! LLVM.IntValue == .i32(2))

		module.dump()
	}

	@Test("Sub IR") func sub() throws {
		let node: BinaryExprSyntax = Parser.parse(expr: "1 - 2")!
		let visitor = CompilerVisitor(builder: builder, module: module)

		let result = try #require(visitor.visit(node, context: module)).as(LLVM.BinaryOperation.self)!

		#expect(result.opcode == LLVMSub)
		#expect(result.lhs as! LLVM.IntValue == .i32(1))
		#expect(result.rhs as! LLVM.IntValue == .i32(2))

		module.dump()
	}

	@Test("let Stmt IR") func letstmt() throws {
		let node = Parser.parse(statement: """
		let foo = 123
		""")!

		let visitor = CompilerVisitor(builder: builder, module: module)
		let result = try #require(visitor.visit(node, context: module))

		#expect(visitor.currentFunction.locals["foo"] == .defined(LLVM.IntValue.i32(123)))
		#expect(result == .void())

		module.dump()
	}
}
