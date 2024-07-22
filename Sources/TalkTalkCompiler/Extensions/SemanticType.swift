//
//  SemanticType.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

import TalkTalkTyper

extension SemanticType {
	func toLLVM(in context: LLVM.Context = .global) -> any LLVM.IR {
		switch self.description {
		case "Int": .i32(context)
		case "Bool": .bool(context)
		default:
			.void(context)
		}
	}
}
