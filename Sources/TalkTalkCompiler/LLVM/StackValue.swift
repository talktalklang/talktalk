//
//  StackValue.swift
//
//
//  Created by Pat Nakajima on 7/18/24.
//

import C_LLVM

extension LLVM {
	class StackValue: IRValue {
		static func ==(lhs: StackValue, rhs: StackValue) -> Bool {
			lhs.ref == rhs.ref
		}

		let ref: LLVMValueRef
		let type: any IRType

		init(ref: LLVMValueRef, type: any IRType) {
			self.ref = ref
			self.type = type
		}

		func store(_ value: any IRValue, in builder: Builder) {
			LLVMBuildStore(builder.ref, value.ref, ref)
		}

		func hash(into hasher: inout Hasher) {
			hasher.combine(ref)
		}
	}
}
