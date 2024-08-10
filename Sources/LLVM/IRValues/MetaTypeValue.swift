//
//  MetaTypeValue.swift
//  LLVM
//
//  Created by Pat Nakajima on 7/30/24.
//

import C_LLVM

public extension LLVM {
	struct MetaType: EmittedValue {
		public var type: LLVM.StructType
		public var ref: LLVMValueRef
		public var vtable: LLVMValueRef?

		public init(type: LLVM.StructType, ref: LLVMValueRef, vtable: LLVMValueRef?) {
			self.type = type
			self.ref = ref
			self.vtable = vtable
		}
	}
}
