//
//  StructType.swift
//  
//
//  Created by Pat Nakajima on 7/23/24.
//

import C_LLVM

extension LLVM {
	struct StructType: IRType {
		var ref: LLVMTypeRef

		init(ref: LLVMTypeRef) {
			self.ref = ref
		}

		func asLLVM<T>() -> T {
			ref as! T
		}
	}

	struct Struct: IRValue {
		var ref: LLVMValueRef

		init(ref: LLVMValueRef) {
			self.ref = ref
		}

		func asLLVM<T>() -> T {
			ref as! T
		}
	}
}
