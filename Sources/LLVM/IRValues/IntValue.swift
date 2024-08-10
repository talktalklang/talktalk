//
//  IntValue.swift
//  C_LLVM
//
//  Created by Pat Nakajima on 7/25/24.
//

import C_LLVM

public extension LLVM {
	struct IntValue: IRValue {
		public let type: IntType
	}

	struct EmittedIntValue: EmittedValue {
		public typealias V = IntValue

		public let type: IntType
		public let ref: LLVMValueRef

		public init(type: IntType, ref: LLVMValueRef) {
			self.type = type
			self.ref = ref
		}
	}
}
