//
//  EmittedStaticFunction.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/1/24.
//

import C_LLVM

public extension LLVM {
	struct EmittedStaticFunction: EmittedValue {
		public let type: FunctionType
		public let ref: LLVMValueRef

		public init(type: FunctionType, ref: LLVMValueRef) {
			self.type = type
			self.ref = ref
		}
	}
}
