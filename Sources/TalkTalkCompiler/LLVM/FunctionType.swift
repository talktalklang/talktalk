//
//  FunctionType.swift
//
//
//  Created by Pat Nakajima on 7/16/24.
//
import C_LLVM

extension LLVM {
	class FunctionType {
		let returning: any LLVMType
		let parameters: [any LLVMType]
		let isVarArg: Bool
		let ref: LLVMTypeRef

		init(context _: LLVM.Context, returning: any LLVMType, parameters: [any LLVMType], isVarArg: Bool) {
			self.returning = returning
			self.parameters = parameters
			self.isVarArg = isVarArg

			var parameterRefs = parameters.map(\.ref).map(Optional.init)
			self.ref = parameterRefs.withUnsafeMutableBufferPointer {
				LLVMFunctionType(returning.ref, $0.baseAddress, UInt32(parameters.count), LLVMBool(isVarArg ? 1 : 0))
			}
		}
	}
}
