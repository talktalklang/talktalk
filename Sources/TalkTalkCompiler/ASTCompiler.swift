//
//  Compiler.swift
//
//
//  Created by Pat Nakajima on 7/15/24.
//
import C_LLVM
import TalkTalkSyntax
import TalkTalkTyper

public struct ASTCompiler {
	enum Error: Swift.Error {
		case typeError([TalkTalkTyper.TypeError])
	}

	let file: SourceFile
	let ast: ProgramSyntax
	let module: LLVM.Module
	let builder: LLVM.Builder

	public init(filename: String, source: String) {
		self.file = SourceFile(path: filename, source: source)
		self.ast = try! SyntaxTree.parse(source: file)
		self.module = LLVM.Module(name: "main", in: .global)
		self.builder = LLVM.Builder(module: module)
	}

	public init(file: SourceFile) {
		self.file = file
		self.ast = try! SyntaxTree.parse(source: file)
		self.module = LLVM.Module(name: "main", in: .global)
		self.builder = LLVM.Builder(module: module)
	}

	public func compile(optimize: Bool = false) throws -> LLVM.Module {
		LLVMInitializeNativeTarget()
		LLVMInitializeNativeAsmParser()
		LLVMInitializeNativeAsmPrinter()

		let bindings = try Typer(source: file).check()

		if !bindings.errors.isEmpty {
			throw Error.typeError(bindings.errors)
		}

		let visitor = CompilerVisitor(bindings: bindings, builder: builder, module: module)
		_ = visitor.visit(ast, context: module)

		var message: UnsafeMutablePointer<Int8>?
		LLVMVerifyModule(module.ref, LLVMPrintMessageAction, &message)

		if let message, String(cString: message) != "" {
			defer { LLVMDisposeMessage(message) }
			fatalError("Error compiling: \(String(cString: message))")
		}

		if optimize {
			LLVM.ModulePassManager(module: module).run()
		}

		return module
	}
}
