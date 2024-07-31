//
//  EmittedType.swift
//  LLVM
//
//  Created by Pat Nakajima on 7/25/24.
//

import C_LLVM

public extension LLVM {
	struct EmittedType<T: IRType>: IRType, Emitted {
		public typealias V = T.V

		public let type: T
		public let typeRef: LLVMTypeRef

		init(type: T, typeRef: LLVMTypeRef) {
			self.type = type
			self.typeRef = typeRef
		}

		public func typeRef(in _: LLVM.Context) -> LLVMTypeRef {
			typeRef
		}

		public func emit(ref: LLVMValueRef) -> any LLVM.EmittedValue {
			type.emit(ref: ref)
		}
	}
}
