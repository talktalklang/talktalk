import C_LLVM

extension LLVM {
	class Emitter {
		let builder: LLVM.Builder
		var currentFunction: Function

		init(module: Module) {
			builder = LLVM.Builder(module: module)

			let mainType = LLVM.FunctionType(
				context: .global,
				returning: .i32(.global),
				parameters: [],
				isVarArg: false
			)

			// Let's get print goin
			var printArgs = [
				LLVMPointerType(
					LLVMInt8TypeInContext(
						builder.module.context.ref
					),
					0
				)
			]

			let printfType = printArgs.withUnsafeMutableBufferPointer {
				LLVMFunctionType(
					LLVMPointerType(
						LLVMInt8TypeInContext(
							module.context.ref
						),
						0
					),
					$0.baseAddress,
					UInt32(1),
					LLVMBool(1)
				)
			}
			_ = LLVMAddFunction(module.ref, "printf", printfType)

			let function = builder.addFunction(named: "main", mainType)!
			let blockRef = LLVMAppendBasicBlockInContext(
				builder.module.context.ref,
				function.ref,
				"entry"
			)

			self.currentFunction = function

			LLVMPositionBuilderAtEnd(builder.ref, blockRef)
		}

		func emit(
			binaryOp: LLVMOpcode,
			lhs: LLVMValueRef,
			rhs: LLVMValueRef,
			name: String = ""
		) -> LLVMValueRef {
			LLVMBuildBinOp(
				builder.ref,
				binaryOp,
				lhs,
				rhs,
				name
			)!
		}

		func emitReturn(_ val: LLVMValueRef) {
			LLVMBuildRet(builder.ref, val)
		}
	}
}
