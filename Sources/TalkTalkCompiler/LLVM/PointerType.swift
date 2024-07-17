//
//  Pointer.swift
//  
//
//  Created by Pat Nakajima on 7/16/24.
//
import C_LLVM

prefix operator *
prefix func *(rhs: any LLVMType) -> LLVM.PointerType {
	LLVM.PointerType(pointee: rhs)
}

extension LLVM {
	class PointerType: LLVMType {
		let ref: LLVMValueRef

		init(pointee: any LLVMType) {
			self.ref = LLVMPointerType(pointee.ref, .zero)
		}
	}
}
