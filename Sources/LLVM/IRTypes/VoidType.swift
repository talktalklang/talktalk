//
//  VoidType.swift
//  LLVM
//
//  Created by Pat Nakajima on 7/27/24.
//

import C_LLVM

public extension LLVM {
	struct VoidValue: EmittedValue {
		public init(type: LLVM.VoidType, ref: LLVMValueRef) {
			fatalError()
		}
		
		public var ref: LLVMValueRef { fatalError() }
		public var type: LLVM.VoidType

		public init() {
			self.type = VoidType()
		}
	}

	struct VoidType: IRType {
		public typealias V = VoidValue

		public init() {}

		public var isVoid: Bool {
			true
		}

		public func typeRef(in _: LLVM.Context) -> LLVMTypeRef {
			LLVMVoidType()
		}

		public func emit(ref: LLVMValueRef) -> any LLVM.EmittedValue {
			LLVM.VoidValue()
		}
	}
}
