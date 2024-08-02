//
//  Constant.swift
//  C_LLVM
//
//  Created by Pat Nakajima on 7/25/24.
//
import C_LLVM

public extension LLVM {
	struct Constant<V: IRValue, Value>: IRValue {
		public let type: V.T
		public let value: V
		public let literal: Value

		public func valueRef(in builder: LLVM.Builder) -> LLVMValueRef {
			switch value {
			case is IntValue where literal is any BinaryInteger:
				let int = literal as! Int
				return LLVMConstInt(type.typeRef(in: builder), UInt64(int), .zero)
			default:
				fatalError("Not implemented yet.")
			}
		}
	}
}
