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

		func process(_ module: LLVM.Module) throws {
			let programSyntax = try SyntaxTree.parse(source: sourceFile)

			let programABT = SemanticASTVisitor(ast: programSyntax).visit()
			if !programABT.scope.errors.isEmpty {
				fatalError(programABT.scope.errors.description)
			}

			let visitor = CompilerABTVisitor(module: module)

			let retval: any LLVM.IR = visitor.visit(programABT)

			switch retval {
			case let retval as any LLVM.IRValue:
				visitor.emitter.emitReturn(retval)
			default:
				visitor.emitter.emitReturn(.i32(0))
			}
		}
	}
}
