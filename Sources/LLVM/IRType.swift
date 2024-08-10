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
		func typeRef(in builder: Builder) -> LLVMTypeRef
		func asReturnType(in builder: Builder) -> LLVMTypeRef
		func emit(ref: LLVMValueRef) -> any EmittedValue
		var isVoid: Bool { get }
	}
}

public extension LLVM.IRType {
	func `as`<T: LLVM.IRType>(_: T.Type) -> T {
		self as! T
	}

	func asPointer() -> LLVM.TypePointer<Self> {
		LLVM.TypePointer(type: self)
	}

	var isVoid: Bool {
		false
	}

	func asReturnType(in builder: LLVM.Builder) -> LLVMTypeRef {
		typeRef(in: builder)
	}
}

extension LLVMOpcode: LLVM.IR {
	public func asLLVM<T>() -> T {
		self as! T
	}
}
