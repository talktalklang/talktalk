//
//  EmittedMethodValue.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/31/24.
//

import C_LLVM

public extension LLVM {
	struct EmittedMethodValue: EmittedValue {
		public let type: LLVM.FunctionType
		public let ref: LLVMValueRef

		public var function: LLVM.EmittedFunctionValue
		public var receiver: LLVM.EmittedStructPointerValue

		public init(function: LLVM.EmittedFunctionValue, receiver: LLVM.EmittedStructPointerValue) {
			self.type = function.type
			self.ref = function.ref

			self.function = function
			self.receiver = receiver
		}
	}
}
