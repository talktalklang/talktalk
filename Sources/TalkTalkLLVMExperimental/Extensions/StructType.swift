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

	func toLLVM(in builder: LLVM.Builder) -> LLVM.StructType {
		let vtablePointerType = LLVM.TypePointer(type: .i8)

		let types = makeLLVMStructTypeList(in: builder) + [vtablePointerType]
		let ref = builder.namedStruct(name: name!, types: types)
		let vtable = builder.vtable(for: ref)

		return LLVM.StructType(
			name: name ?? "<anon struct>",
			types: types,
			offsets: propertyOffsets,
			namedTypeRef: ref,
			vtable: vtable
		)
	}
}
