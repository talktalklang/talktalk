//
//  Pointer.swift
//
//
//  Created by Pat Nakajima on 7/16/24.
//
import C_LLVM

prefix operator *
prefix func * (rhs: any LLVM.IRType) -> LLVM.PointerType {
	LLVM.PointerType(pointee: rhs)
}

extension LLVM {
	class PointerType: LLVM.IRType, Hashable {
		static func == (lhs: PointerType, rhs: PointerType) -> Bool {
			lhs.ref == rhs.ref
		}

		let ref: LLVMTypeRef

		init(pointee: any LLVM.IRType) {
			self.ref = LLVMPointerType(pointee.ref, .zero)
		}

		func hash(into hasher: inout Hasher) {
			hasher.combine(ref)
		}

		func asLLVM<T>() -> T {
			ref as! T
		}
	}
}
