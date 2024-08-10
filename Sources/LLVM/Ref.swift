//
//  Ref.swift
//  LLVM
//
//  Created by Pat Nakajima on 7/25/24.
//

import C_LLVM

public extension LLVM {
	protocol IRValueRef {
		var ref: LLVMValueRef { get }
	}
}
