//
//  EmittedValue.swift
//  LLVM
//
//  Created by Pat Nakajima on 7/25/24.
//

import C_LLVM

public extension LLVM {
	protocol EmittedValue: IRValue, IRValueRef, Emitted where T: IRType {
		var type: T { get }
		var ref: LLVMValueRef { get }
	}
}

public extension LLVM.EmittedValue {
	func `as`<T: LLVM.EmittedValue>(_: T.Type) -> T {
		self as! T
	}
}
