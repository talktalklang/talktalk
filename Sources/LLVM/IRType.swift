//
//  LLVMType.swift
//
//
//  Created by Pat Nakajima on 7/16/24.
//
import C_LLVM

public extension LLVM {
	protocol IRType<V>: IR {
		associatedtype V: IRValue
		func typeRef(in context: Context) -> LLVMTypeRef
		func asReturnType(in context: Context) -> LLVMTypeRef
		func emit(ref: LLVMValueRef) -> any EmittedValue
		var isVoid: Bool { get }
	}
}

public extension LLVM.IRType {
	func `as`<T: LLVM.IRType>(_: T.Type) -> T {
		self as! T
	}

	var isVoid: Bool {
		false
	}

	func asReturnType(in context: LLVM.Context) -> LLVMTypeRef {
		typeRef(in: context)
	}
}

extension LLVMOpcode: LLVM.IR {
	public func asLLVM<T>() -> T {
		self as! T
	}
}
