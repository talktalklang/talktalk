//
//  Compiler.swift
//
//
//  Created by Pat Nakajima on 7/15/24.
//
import C_LLVM
import TalkTalkSyntax

public struct Compiler {
	let ast: ProgramSyntax
	let module: LLVM.Module
	let builder: LLVM.Builder

	public init(source: String) {
		ast = try! SyntaxTree.parse(source: source)
		module = LLVM.Module(name: "main", in: .global)
		builder = LLVM.Builder(module: module)
	}

	public func compile() throws {
		// Initialize LLVM
		LLVMInitializeNativeTarget()
		LLVMInitializeNativeAsmPrinter()
		LLVMInitializeNativeAsmParser()

		let mainType = LLVM.FunctionType(
			context: .global,
			returning: .i32(.global),
			parameters: [],
			isVarArg: false
		)

		let function = builder.addFunction(named: "main", mainType)!
		let blockRef = LLVMAppendBasicBlockInContext(module.context.ref, function.ref, "entry")

		LLVMPositionBuilderAtEnd(builder.ref, blockRef)

		let visitor = CompilerVisitor(ast: ast, builder: builder, module: module)
		_ = visitor.visit(ast, context: module)

		module.dump()

		var message: UnsafeMutablePointer<Int8>?
		LLVMVerifyModule(module.ref, LLVMAbortProcessAction, &message)

		if let message {
			defer { LLVMDisposeMessage(message) }
			print(String(cString: message))
		}
	}
}
