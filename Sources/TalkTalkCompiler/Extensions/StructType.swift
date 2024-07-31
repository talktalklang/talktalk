//
//  StructType.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/30/24.
//

import TalkTalkAnalysis
import LLVM
import C_LLVM

public extension TalkTalkAnalysis.StructType {
	func makeLLVMStructTypeList(in builder: LLVM.Builder) -> [any LLVM.IRType] {
		let sorted = propertyOffsets.sorted(by: { $0.value < $1.value })
		return sorted.map { properties[$0.key]!.type.irType(in: builder) }
	}

	func toLLVM(in builder: LLVM.Builder, vtable: LLVMValueRef?) -> LLVM.StructType {
		let vtablePointerType = LLVM.TypePointer(type: .i8)

		let types = [vtablePointerType] + makeLLVMStructTypeList(in: builder)
		let ref = builder.namedStruct(name: name!, types: types)

		return LLVM.StructType(
			name: name ?? "<anon struct>",
			types: types,
			offsets: propertyOffsets,
			namedTypeRef: ref,
			vtable: vtable
		)
	}
}
