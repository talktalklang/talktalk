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

		func `as`<T>(_: T.Type) -> T? {
			switch self {
			case let .value(value):
				value as? T
			case let .op(opcode):
				opcode as? T
			case let .type(_type):
				_type as? T
			}
		}

		func unwrap<T>() -> T {
			if let result = self.as(T.self) {
				return result
			} else {
				fatalError("Could not unwrap \(self) to \(T.self)")
			}
		}

		func hash(into hasher: inout Hasher) {
			switch self {
			case let .value(v):
				hasher.combine(v)
			case let .type(t):
				hasher.combine(t)
			case let .op(ref):
				hasher.combine(ref.rawValue)
			}
		}
	}

	protocol IRValue: IR, Hashable, Equatable {
		var ref: LLVMValueRef { get }
	}
}
