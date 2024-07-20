//
//  HeapValue.swift
//  
//
//  Created by Pat Nakajima on 7/19/24.
//

import C_LLVM

extension LLVM {
	class HeapValue: IRValue {
		static func ==(lhs: HeapValue, rhs: HeapValue) -> Bool {
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
