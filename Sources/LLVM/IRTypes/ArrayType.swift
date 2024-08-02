//
//  ArrayType.swift
//  LLVM
//
//  Created by Pat Nakajima on 7/30/24.
//

import C_LLVM

public extension LLVM {
	struct ArrayType: IRType {
		public typealias V = ArrayValue
		let elementType: any IRType
		let capacity: Int

		public init(elementType: any IRType, capacity: Int) {
			self.elementType = elementType
			self.capacity = capacity
		}

		public func typeRef(in builder: LLVM.Builder) -> LLVMTypeRef {
			LLVMArrayType(elementType.typeRef(in: builder), UInt32(capacity))
		}
		
		public func emit(ref: LLVMValueRef) -> any LLVM.EmittedValue {
			LLVM.EmittedArrayValue(type: self, ref: ref)
		}
	}

	struct EmittedArrayValue: EmittedValue {
		public var type: ArrayType
		public var ref: LLVMValueRef

		public init(type: ArrayType, ref: LLVMValueRef) {
			self.type = type
			self.ref = ref
		}
	}

	struct ArrayValue: IRValue {
		public var type: LLVM.ArrayType
		public let ref: LLVMValueRef

		public init(type: LLVM.ArrayType, ref: LLVMValueRef) {
			self.type = type
			self.ref = ref
		}
	}
}
