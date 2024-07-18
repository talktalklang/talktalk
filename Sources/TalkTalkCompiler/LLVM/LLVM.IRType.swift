//
//  LLVMType.swift
//
//
//  Created by Pat Nakajima on 7/16/24.
//
import C_LLVM

extension LLVM {
	protocol IRType: Hashable {
		var ref: LLVMTypeRef { get }
	}
}
