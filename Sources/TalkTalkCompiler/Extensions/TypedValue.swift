//
//  TypedValue.swift
//  
//
//  Created by Pat Nakajima on 7/18/24.
//
import C_LLVM
import TalkTalkTyper

extension TypedValue {
	func llvmType(in context: LLVM.Context) -> any LLVM.IRType {
		switch type {
		case .int: .i32(context)
		case .bool: .i1(context)
		default:
			fatalError("not handled")
		}
	}
}
