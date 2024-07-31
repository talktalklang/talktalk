//
//  CapturesStruct.swift
//  LLVM
//
//  Created by Pat Nakajima on 7/27/24.
//

import C_LLVM

public extension LLVM {
	struct CapturesStructType: LLVM.IRType {
		public typealias V = CapturesStruct
		let name: String
		let types: [any LLVM.IRType]

		public init(name: String, types: [any LLVM.IRType]) {
			self.name = name
			self.types = types
		}

		public func typeRef(in context: LLVM.Context) -> LLVMTypeRef {
			var types: [LLVMTypeRef?] = types.map { LLVMPointerType($0.typeRef(in: context), 0) }
			return types.withUnsafeMutableBufferPointer {
				let ref = LLVMStructCreateNamed(context.ref, name)
				LLVMStructSetBody(ref, $0.baseAddress, UInt32($0.count), .zero)
				return ref!
			}
		}
		
		public func emit(ref: LLVMValueRef) -> any LLVM.EmittedValue {
			fatalError()
		}
	}

	struct CapturesStruct: LLVM.IRValue, LLVM.StoredPointer {
		public typealias T = CapturesStructType
		public var type: LLVM.CapturesStructType
		public var ref: LLVMValueRef

		public var offsets: [String: Int] = [:]
		public var captures: [any LLVM.StoredPointer] = []

		public init(type: LLVM.CapturesStructType, offsets: [String: Int], captures: [any LLVM.StoredPointer], ref: LLVMValueRef) {
			self.type = type
			self.offsets = offsets
			self.captures = captures
			self.ref = ref
		}

		public init(type: LLVM.CapturesStructType, ref: LLVMValueRef) {
			self.type = type
			self.ref = ref
		}

		public var isHeap: Bool {
			true
		}

		public func typeRef(in _: LLVM.Context) -> LLVMTypeRef {
			ref
		}
	}
}
