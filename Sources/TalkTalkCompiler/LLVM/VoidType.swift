//
//  Void.swift
//  
//
//  Created by Pat Nakajima on 7/16/24.
//
import C_LLVM

extension LLVM {
	class VoidType: LLVMType {
		let ref: LLVMTypeRef

		init(context: LLVM.Context) {
			self.ref = LLVMVoidTypeInContext(context.ref)
		}
	}
}

extension LLVMType where Self == LLVM.VoidType {
	static func void(_ context: LLVM.Context) -> LLVM.VoidType {
		LLVM.VoidType(context: context)
	}
}
