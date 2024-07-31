//
//  FunctionPointer.swift
//  LLVM
//
//  Created by Pat Nakajima on 7/27/24.
//

import C_LLVM

public extension LLVM {
	struct FunctionPointerType: IRType {
		public typealias V = FunctionPointer

		let functionType: FunctionType

		public func typeRef(in context: LLVM.Context) -> LLVMTypeRef {
			if let captures = functionType.captures, !captures.types.isEmpty {
				CapturesStructType(name: "\(functionType.name)fnPtrWithEnv", types: [functionType, captures]).typeRef(in: context)
			} else {
				CapturesStructType(name: "\(functionType.name)fnPtr", types: [functionType]).typeRef(in: context)
			}
		}

		public func emit(ref: LLVMValueRef) -> any LLVM.EmittedValue {
			fatalError()
		}
	}

	struct FunctionEnvironmentPointerType: IRType {
		public typealias V = CapturesStruct

		public let envStructType: StructType

		public func typeRef(in context: LLVM.Context) -> LLVMTypeRef {
			LLVMPointerType(envStructType.typeRef(in: context), 0)
		}

		public func emit(ref: LLVMValueRef) -> any LLVM.EmittedValue {
			fatalError()
		}
	}

	struct FunctionPointer: LLVM.StoredPointer {
		public var type: LLVM.FunctionPointerType

		public typealias T = FunctionPointerType
		public var ref: LLVMValueRef

		public var isHeap: Bool

		public init(type: LLVM.FunctionPointerType, ref: LLVMValueRef) {
			self.type = type
			self.ref = ref
			self.isHeap = type.functionType.captures != nil
		}
	}
}
