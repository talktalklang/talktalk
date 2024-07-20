//
//  Void.swift
//
//
//  Created by Pat Nakajima on 7/16/24.
//
import C_LLVM

extension LLVM {
	class VoidType: LLVM.IRType {
		static func == (_: LLVM.VoidType, _: LLVM.VoidType) -> Bool {
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

extension LLVM.IRType where Self == LLVM.VoidType {
	static func void(_ context: LLVM.Context = .global) -> any LLVM.IRType {
		LLVM.VoidType(context: context)
	}
}

extension LLVM.IRValueRef {
	static func void(_ context: LLVM.Context = .global) -> LLVM.IRValueRef {
		.type(.void(context))
	}
}
