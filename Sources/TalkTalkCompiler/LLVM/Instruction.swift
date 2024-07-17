//
//  Instruction.swift
//  
//
//  Created by Pat Nakajima on 7/17/24.
//
import C_LLVM

extension LLVM {
	class BinaryOperation: Hashable, IRValue {
		static func == (lhs: LLVM.BinaryOperation, rhs: LLVM.BinaryOperation) -> Bool {
			lhs.opcode == rhs.opcode && lhs == rhs
		}

		let opcode: LLVMOpcode
		let lhs: any IRValue
		let rhs: any IRValue
		let ref: LLVMValueRef

		init(opcode: LLVMOpcode, lhs: any IRValue, rhs: any IRValue, ref: LLVMValueRef) {
			self.opcode = opcode
			self.lhs = lhs
			self.rhs = rhs
			self.ref = ref
		}

		func hash(into hasher: inout Hasher) {
			hasher.combine(opcode.rawValue)
			hasher.combine(lhs)
			hasher.combine(rhs)
		}
	}
}
