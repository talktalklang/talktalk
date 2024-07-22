//
//  Pipeline.swift
//  
//
//  Created by Pat Nakajima on 7/22/24.
//

import TalkTalkSyntax
import TalkTalkTyper
import C_LLVM

extension Compiler {
	struct Pipeline {
		let sourceFile: SourceFile

		init(sourceFile: SourceFile) {
			self.sourceFile = sourceFile
		}

		func process(_ module: LLVM.Module) {
			let programSyntax = Parser.parse(file: sourceFile)
			let programABT = SemanticASTVisitor(ast: programSyntax).visit()
			let visitor = CompilerABTVisitor(module: module)

			let retval: LLVMValueRef = visitor.visit(programABT).asLLVM()
			visitor.emitter.emitReturn(retval)
		}
	}
}
