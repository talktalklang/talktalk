//
//  Void.swift
//
//
//  Created by Pat Nakajima on 7/16/24.
//
import C_LLVM

extension LLVM {
	class VoidType: LLVMType {
		static func == (lhs: LLVM.VoidType, rhs: LLVM.VoidType) -> Bool {
			true
		}
		
		let ref: LLVMTypeRef

		init(context: LLVM.Context) {
			self.ref = LLVMVoidTypeInContext(context.ref)
		}

		func hash(into hasher: inout Hasher) {
			hasher.combine(0)
		}
	}
}


extension LLVMType where Self == LLVM.VoidType {
	static func void(_ context: LLVM.Context = .global) -> any LLVMType {
		LLVM.VoidType(context: context)
	}
}

extension LLVM.IRValueRef {
	static func void(_ context: LLVM.Context = .global) -> LLVM.IRValueRef {
		.type(.void(context))
	}
}
