//
//  Builtins+printf.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/29/24.
//

import LLVM
import C_LLVM

extension Builtins {
	struct Printf: LLVM.BuiltinFunction {
		static let name = "printf"

		var functionType: LLVMTypeRef
		var functionRef: LLVMValueRef
		var formatStrPtr: LLVMValueRef

		init(module: LLVMModuleRef, builder: LLVM.Builder) {
			formatStrPtr = builder.global(string: "%d\n", name: "fmtStr")
			var printfArgsType = LLVMPointerType(LLVMInt8Type(), 0)
			functionType = LLVMFunctionType(LLVMInt32Type(), &printfArgsType, 1, LLVMBool(1))
			functionRef = LLVMAddFunction(module, "printf", functionType)
		}

		func call(with arguments: inout [LLVMValueRef?], builder: LLVMBuilderRef) -> any LLVM.EmittedValue {
			arguments.insert(formatStrPtr, at: 0)

			let ref = arguments.withUnsafeMutableBufferPointer {
				LLVMBuildCall2(
					builder,
					functionType,
					functionRef,
					$0.baseAddress,
					UInt32($0.count),
					"printfCall"
				)!
			}

			return LLVM.EmittedIntValue(type: .i32, ref: ref)
		}
	}
}
