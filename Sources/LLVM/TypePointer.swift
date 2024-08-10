//
//  TypePointer.swift
//  LLVM
//
//  Created by Pat Nakajima on 7/25/24.
//

import C_LLVM

public extension LLVM {
	struct TypePointer<T: IRType>: IRType {
		public typealias V = T.V

		var type: T

		public init(type: T) {
			self.type = type
		}

		public func typeRef(in builder: LLVM.Builder) -> LLVMTypeRef {
			LLVMPointerType(type.typeRef(in: builder), 0)
		}

		public func emit(ref: LLVMValueRef) -> any LLVM.EmittedValue {
			type.emit(ref: ref)
		}
	}
}
