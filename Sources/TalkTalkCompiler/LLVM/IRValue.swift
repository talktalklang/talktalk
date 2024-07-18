//
//  IRValue.swift
//
//
//  Created by Pat Nakajima on 7/16/24.
//
import C_LLVM

extension LLVM {
	enum IRValueRef: Equatable, Hashable {
		static func == (lhs: LLVM.IRValueRef, rhs: LLVM.IRValueRef) -> Bool {
			lhs.hashValue == rhs.hashValue
		}
		
		case value(any IRValue),
				 op(LLVMOpcode),
				 type(any LLVM.IRType)

		func `as`<T>(_ type: T.Type) -> T? {
			switch self {
			case .value(let value):
				value as? T
			case .op(let opcode):
				opcode as? T
			case .type(let _type):
				_type as? T
			}
		}

		func unwrap<T>() -> T {
			switch self {
			case .value(let value):
				value as! T
			case .op(let opcode):
				opcode as! T
			case .type(let _type):
				_type as! T
			}
		}

		func hash(into hasher: inout Hasher) {
			switch self {
			case .value(let v):
				hasher.combine(v)
			case .type(let t):
				hasher.combine(t)
			case .op(let ref):
				hasher.combine(ref.rawValue)
			}
		}
	}

	protocol IRValue: Hashable, Equatable {
		var ref: LLVMValueRef { get }
	}
}

extension LLVMValueRef: LLVM.IRValue {
	var ref: LLVMValueRef {
		self
	}
}
