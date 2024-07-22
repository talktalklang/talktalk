//
//  Value.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

import TalkTalkTyper

extension Value {
	func get(in context: LLVM.Context = .global) -> any LLVM.IRValue {
		switch self {
		case let value as Int:
			.i32(value, in: context)
		default:
			.i1(0)
		}
	}
}
