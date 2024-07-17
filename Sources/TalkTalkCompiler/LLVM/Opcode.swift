//
//  Opcode.swift
//
//
//  Created by Pat Nakajima on 7/17/24.
//

import C_LLVM

extension LLVM {
	enum Opcode {
		case add, ret

		/// Creates an `OpCode` from an `LLVMOpcode`
		init(rawValue: LLVMOpcode) {
			switch rawValue {
			case LLVMAdd: self = .add
			case LLVMRet: self = .ret
			default:
				fatalError()
			}
		}

		var ref: LLVM.IRValueRef {
			switch self {
			case .add:
				.op(LLVMAdd)
			case .ret:
				.op(LLVMRet)
			}
		}
	}
}
