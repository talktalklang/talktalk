//
//  LLVMType.swift
//  
//
//  Created by Pat Nakajima on 7/16/24.
//
import C_LLVM

protocol LLVMType: LLVM.IRValue {
	var ref: LLVMTypeRef { get }
}
