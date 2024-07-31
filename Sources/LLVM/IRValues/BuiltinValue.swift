//
//  BuiltinValue.swift
//  LLVM
//
//  Created by Pat Nakajima on 7/29/24.
//

import C_LLVM

public extension LLVM {
	struct BuiltinValue: EmittedValue {
		public var ref: LLVMValueRef
		public var type: LLVM.BuiltinType
		
		public init(type: LLVM.BuiltinType, ref: LLVMValueRef) {
			self.type = type
			self.ref = ref
		}
	}
}
