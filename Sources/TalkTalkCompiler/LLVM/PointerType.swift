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

		let pointee: any LLVM.IRType
		let ref: LLVMTypeRef

		init(pointee: any LLVM.IRType) {
			self.pointee = pointee
			self.ref = LLVMPointerType(pointee.ref, .zero)
		}

		func hash(into hasher: inout Hasher) {
			hasher.combine(ref)
		}

		func asLLVM<T>() -> T {
			ref as! T
		}
	}

	class Pointer: LLVM.IRValue {
		func asLLVM<T>() -> T {
			ref as! T
		}
		
		static func == (lhs: Pointer, rhs: Pointer) -> Bool {
			lhs.ref == rhs.ref
		}

		public let type: PointerType
		public let ref: LLVMValueRef

		public init(type: PointerType, ref: LLVMValueRef) {
			self.type = type
			self.ref = ref
		}

		public func hash(into hasher: inout Hasher) {
			hasher.combine(ref)
		}
	}
}
