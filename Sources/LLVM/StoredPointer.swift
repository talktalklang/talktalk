//
//  StoredPointer.swift
//  LLVM
//
//  Created by Pat Nakajima on 7/25/24.
//

import C_LLVM

public extension LLVM {
	protocol StoredPointer: EmittedValue where T: IRType {
		var type: T { get }
		var ref: LLVMValueRef { get }

		var isHeap: Bool { get }

		init(type: T, ref: LLVMValueRef)
	}
}

public extension LLVM.StoredPointer {
	var isPointer: Bool {
		true
	}
}
