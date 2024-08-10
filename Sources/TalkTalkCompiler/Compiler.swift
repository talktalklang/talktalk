//
//  Compiler.swift
//
//
//  Created by Pat Nakajima on 7/21/24.
//

import TalkTalkTyper
import TalkTalkSyntax
import C_LLVM

public class Compiler {
	let sourceFile: SourceFile
	let pipeline: Compiler.Pipeline
	let module: LLVM.Module

	public init(sourceFile: SourceFile) {
		self.sourceFile = sourceFile
		self.module = LLVM.Module(name: "main", in: .global)
		self.pipeline = Pipeline(sourceFile: sourceFile)
	}

	public func compile() throws -> LLVM.Module {
		LLVMInitializeNativeTarget()
		LLVMInitializeNativeAsmParser()
		LLVMInitializeNativeAsmPrinter()

		try pipeline.process(module)
		return module
	}
}
