//
//  LLVMType.swift
//
//
//  Created by Pat Nakajima on 7/16/24.
//
import C_LLVM

extension LLVM {
	protocol IRType: IR, Hashable {
		var ref: LLVMTypeRef { get }
	}
}

extension LLVMOpcode: LLVM.IR {
	public func asLLVM<T>() -> T {
		self as! T
	}
}
