//
//  BuiltinType.swift
//  LLVM
//
//  Created by Pat Nakajima on 7/29/24.
//

import C_LLVM

public extension LLVM {
	struct BuiltinType: IRType {
		public typealias V = BuiltinValue
		public let name: String

		public init(name: String) {
			self.name = name
		}

		public func typeRef(in builder: LLVM.Builder) -> LLVMTypeRef {
			fatalError("builtin types should not be referenced")
		}

		public func emit(ref: LLVMValueRef) -> any LLVM.EmittedValue {
			fatalError("builtin types cannot be emitted")
		}
	}
}
