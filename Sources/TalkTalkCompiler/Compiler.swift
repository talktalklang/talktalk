//
//  Compiler.swift
//
//
//  Created by Pat Nakajima on 7/15/24.
//
import C_LLVM
import TalkTalkTyper
import TalkTalkSyntax

public struct Compiler {
	enum Error: Swift.Error {
		case typeError([TalkTalkTyper.TypeError])
	}

	let ast: ProgramSyntax
	let module: LLVM.Module
	let builder: LLVM.Builder

	public init(source: String) {
		self.ast = try! SyntaxTree.parse(source: source)
		self.module = LLVM.Module(name: "main", in: .global)
		self.builder = LLVM.Builder(module: module)
	}

	public func compile() throws -> LLVM.Module {
		let bindings = Typer(ast: ast).check()

		if !bindings.errors.isEmpty {
			throw Error.typeError(bindings.errors)
		}

		let visitor = CompilerVisitor(bindings: bindings, builder: builder, module: module)
		_ = visitor.visit(ast, context: module)

		module.dump()

		var message: UnsafeMutablePointer<Int8>?
		LLVMVerifyModule(module.ref, LLVMAbortProcessAction, &message)

		if let message {
			defer { LLVMDisposeMessage(message) }
			print(String(cString: message))
		}

		return module
	}
}
