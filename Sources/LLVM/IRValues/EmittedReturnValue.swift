//
//  EmittedReturnValue.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/1/24.
//

import C_LLVM

public extension LLVM {
	struct EmittedReturnValue: EmittedValue {
		public var type = VoidType() // Just for protocol conformance
		public var value: any EmittedValue
		public var ref: LLVMValueRef

		public init(value: any EmittedValue) {
			self.type = VoidType()
			self.value = value
			self.ref = value.ref
		}
	}
}
