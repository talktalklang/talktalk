//
//  EmittedStaticMethod.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/1/24.
//

import C_LLVM

public extension LLVM {
	struct EmittedStaticMethod: EmittedValue {
		public let name: String
		public let receiver: EmittedStructPointerValue
		public let type: LLVM.FunctionType
		public var ref: LLVMValueRef

		public init(name: String, receiver: EmittedStructPointerValue, type: LLVM.FunctionType, ref: LLVMValueRef) {
			self.name = name
			self.receiver = receiver
			self.type = type
			self.ref = ref
		}
	}
}
