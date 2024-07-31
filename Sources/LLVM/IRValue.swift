//
//  IRValue.swift
//
//
//  Created by Pat Nakajima on 7/16/24.
//
import C_LLVM

public extension LLVM {
	protocol IRValue: IR {
		associatedtype T: IRType

		var type: T { get }
	}

	struct RawValueType: IRType {
		public typealias V = RawValue

		public func typeRef(in _: LLVM.Context) -> LLVMTypeRef {
			fatalError()
		}

		public func emit(ref: LLVMValueRef) -> any LLVM.EmittedValue {
			fatalError()
		}
	}

	struct RawValue: IRValue {
		public let type = RawValueType()
		public let ref: LLVMValueRef
	}
}

public extension LLVM.IRValue where Self == LLVM.RawValue {
	static func raw(_ ref: LLVMValueRef) -> LLVM.RawValue {
		LLVM.RawValue(ref: ref)
	}
}

public extension LLVM.IRValue {
	var isPointer: Bool {
		false
	}
}
