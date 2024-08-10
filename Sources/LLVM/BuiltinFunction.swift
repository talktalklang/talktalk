//
//  BuiltinFunction.swift
//  LLVM
//
//  Created by Pat Nakajima on 7/29/24.
//

import C_LLVM

public extension LLVM {
	// A builtin function can be defined and called at compile time instead of doing the whole
	// pointer dance. I'm not sure if this is the right level of abstraction yet but for now it
	// works for printf().
	protocol BuiltinFunction {
		static var name: String { get }

		init(module: LLVMModuleRef, builder: Builder)

		func call(with arguments: inout [LLVMValueRef?], builder: LLVMBuilderRef) -> any EmittedValue
	}
}
