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

	public init(filename: String, source: String) {
		self.ast = try! SyntaxTree.parse(filename: filename, source: source)
		self.module = LLVM.Module(name: "main", in: .global)
		self.builder = LLVM.Builder(module: module)
	}

	public func compile(optimize: Bool = false) throws -> LLVM.Module {
		LLVMInitializeNativeTarget()
		LLVMInitializeNativeAsmParser()
		LLVMInitializeNativeAsmPrinter()

		let bindings = Typer(ast: ast).check()

		if !bindings.errors.isEmpty {
			throw Error.typeError(bindings.errors)
		}

		let visitor = CompilerVisitor(bindings: bindings, builder: builder, module: module)
		_ = visitor.visit(ast, context: module)

		var message: UnsafeMutablePointer<Int8>?
		LLVMVerifyModule(module.ref, LLVMPrintMessageAction, &message)

		if let message, String(cString: message) != "" {
			defer { LLVMDisposeMessage(message) }
			print("Error compiling: \(String(cString: message))")
			exit(1)
		}

		if optimize {
			LLVM.ModulePassManager(module: module).run()
		}

		return module
	}
}
