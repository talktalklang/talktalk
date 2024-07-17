//
//  Function.swift
//
//
//  Created by Pat Nakajima on 7/16/24.
//
import C_LLVM

extension LLVM {
	class Function {
		let ref: LLVMValueRef

		init(ref: LLVMValueRef) {
			self.ref = ref
		}
	}
}
