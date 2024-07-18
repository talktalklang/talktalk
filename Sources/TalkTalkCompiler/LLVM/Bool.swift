//
//  Bool.swift
//  
//
//  Created by Pat Nakajima on 7/18/24.
//
import C_LLVM

extension LLVMBool {
	init(_ bool: Bool) {
		self = bool ? LLVMBool(1) : LLVMBool(0)
	}
}
