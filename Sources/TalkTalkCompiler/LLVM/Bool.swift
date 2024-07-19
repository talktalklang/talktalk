//
//  Bool.swift
//  
//
//  Created by Pat Nakajima on 7/18/24.
//
import C_LLVM

extension LLVMBool {
	static var `true`: LLVMBool { LLVMBool(1) }
	static var `false`: LLVMBool { LLVMBool(0) }

	init(_ bool: Bool) {
		self = bool ? LLVMBool(1) : LLVMBool(0)
	}
}
