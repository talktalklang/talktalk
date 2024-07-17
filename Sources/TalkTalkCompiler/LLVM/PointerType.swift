//
//  Pointer.swift
//
//
//  Created by Pat Nakajima on 7/16/24.
//
import C_LLVM

prefix operator *
prefix func * (rhs: any LLVMType) -> LLVM.PointerType {
	LLVM.PointerType(pointee: rhs)
}

extension LLVM {
	class PointerType: LLVMType, Hashable {
		static func ==(lhs: PointerType, rhs: PointerType) -> Bool {
			lhs.ref == rhs.ref
		}

		let ref: LLVMTypeRef

		init(pointee: any LLVMType) {
			self.ref = LLVMPointerType(pointee.ref, .zero)
		}

		func hash(into hasher: inout Hasher) {
			hasher.combine(ref)
		}
	}
}
