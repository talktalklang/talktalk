//
//  FunctionType.swift
//
//
//  Created by Pat Nakajima on 7/16/24.
//
import C_LLVM

extension LLVM {
	class FunctionType {
		let returning: any LLVM.IRType
		let parameters: [(String, any LLVM.IRType)]
		let parameterRefs: [LLVMTypeRef?]
		let isVarArg: Bool
		let ref: LLVMTypeRef

		init(
			context _: LLVM.Context,
			returning: any LLVM.IRType,
			parameters: [(String, any LLVM.IRType)],
			isVarArg: Bool
		) {
			self.returning = returning
			self.parameters = parameters
			self.isVarArg = isVarArg

			if parameters.isEmpty {
				self.parameterRefs = []
				self.ref = LLVMFunctionType(
					returning.ref,
					nil,
					UInt32(0),
					LLVMBool(isVarArg ? 1 : 0)
				)
			} else {
				var parameterRefs = parameters.map { $0.1.ref as LLVMTypeRef? }
				self.parameterRefs = parameterRefs
				let ref = parameterRefs.withUnsafeMutableBufferPointer {
					LLVMFunctionType(
						returning.ref,
						$0.baseAddress,
						UInt32(parameters.count),
						LLVMBool(isVarArg ? 1 : 0)
					)
				}!

				self.ref = ref
			}
		}
	}
}
