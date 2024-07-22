//
//  Bool.swift
//
//
//  Created by Pat Nakajima on 7/18/24.
//
import C_LLVM

extension LLVMBool: LLVM.IR {
	static var `true`: LLVMBool { LLVMBool(1) }
	static var `false`: LLVMBool { LLVMBool(0) }

	init(_ bool: Bool) {
		self = bool ? LLVMBool(1) : LLVMBool(0)
	}

	public func asLLVM<T>() -> T {
		self as! T
	}
}

extension LLVM.IR where Self == LLVMBool {
	static func bool(_ context: LLVM.Context) -> LLVM.IntType {
		LLVM.IntType.i1(context)
	}
}

