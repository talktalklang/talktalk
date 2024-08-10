//
//  CapturesStruct.swift
//  LLVM
//
//  Created by Pat Nakajima on 7/27/24.
//

import C_LLVM

//public extension LLVM {
//	struct xCapturesStructType: LLVM.IRType {
//		public typealias V = CapturesStruct
//		let name: String
//		public let types: [any LLVM.IRType]
//
//		public init(name: String, types: [any LLVM.IRType]) {
//			self.name = name
//			self.types = types
//		}
//
//		public func typeRef(in builder: LLVM.Builder) -> LLVMTypeRef {
//			return builder.pointerStruct(name: name, types: types)
//		}
//		
//		public func emit(ref: LLVMValueRef) -> any LLVM.EmittedValue {
//			fatalError()
//		}
//	}
//
//	struct xCapturesStruct: LLVM.IRValue, LLVM.StoredPointer {
//		public typealias T = CapturesStructType
//		public var type: LLVM.CapturesStructType
//		public var ref: LLVMValueRef
//
//		public var offsets: [String: Int] = [:]
//		public var captures: [any LLVM.StoredPointer] = []
//
//		public init(type: LLVM.CapturesStructType, offsets: [String: Int], captures: [any LLVM.StoredPointer], ref: LLVMValueRef) {
//			self.type = type
//			self.offsets = offsets
//			self.captures = captures
//			self.ref = ref
//		}
//
//		public init(type: LLVM.CapturesStructType, ref: LLVMValueRef) {
//			self.type = type
//			self.ref = ref
//		}
//
//		public var isHeap: Bool {
//			true
//		}
//
//		public func typeRef(in _: LLVM.Context) -> LLVMTypeRef {
//			ref
//		}
//	}
//}
