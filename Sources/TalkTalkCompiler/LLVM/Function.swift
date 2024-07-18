//
//  Function.swift
//
//
//  Created by Pat Nakajima on 7/16/24.
//
import C_LLVM

enum VariableState: Equatable {
	static func ==(lhs: VariableState, rhs: VariableState) -> Bool {
		switch lhs {
		case .declared:
			if case .declared = rhs {
				return true
			}
		case .defined(let value):
			if case let .defined(other) = rhs {
				return value.hashValue == other.hashValue
			}
		}

		return false
	}

	case declared, defined(any LLVM.IRValue)
}

extension LLVM {
	class Function {
		let type: FunctionType
		let ref: LLVMValueRef
		var locals: [String: VariableState] = [:]

		init(type: FunctionType, ref: LLVMValueRef) {
			self.type = type
			self.ref = ref
		}
	}
}
