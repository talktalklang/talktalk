//
//  PhiNode.swift
//  LLVM
//
//  Created by Pat Nakajima on 7/25/24.
//

import C_LLVM

public extension LLVM {
	struct PhiNode<T: IRType>: EmittedValue {
		public var type: T
		public var ref: LLVMValueRef

		public init(type: T, ref: LLVMValueRef) {
			self.type = type
			self.ref = ref
		}
	}
}
