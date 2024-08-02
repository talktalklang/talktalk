//
//  StructType.swift
//  LLVM
//
//  Created by Pat Nakajima on 7/30/24.
//
import C_LLVM

public extension LLVM {
	struct StructType: LLVM.IRType {
		public typealias V = StructInstanceValue
		public let types: [any LLVM.IRType]

		let name: String
		let offsets: [String: Int]
		let namedTypeRef: LLVMTypeRef?
		let vtable: LLVMValueRef?

		public init(name: String, types: [any LLVM.IRType], offsets: [String: Int], namedTypeRef: LLVMTypeRef?, vtable: LLVMValueRef?) {
			self.name = name
			self.types = types
			self.offsets = offsets
			self.namedTypeRef = namedTypeRef
			self.vtable = vtable
		}

		public func offset(for name: String) -> Int {
			offsets[name]!
		}

		public func typeRef(in builder: LLVM.Builder) -> LLVMTypeRef {
			if let namedTypeRef {
				return namedTypeRef
			}

			var types: [LLVMTypeRef?] = types.map { $0.typeRef(in: builder) }
			return types.withUnsafeMutableBufferPointer {
				let ref = LLVMStructCreateNamed(builder.context.ref, name)
				LLVMStructSetBody(ref, $0.baseAddress, UInt32($0.count), .zero)
				return ref!
			}
		}

		public func pointer(in builder: LLVM.Builder) -> any StoredPointer {
			HeapValue(type: self, ref: typeRef(in: builder))
		}

		public func emit(ref: LLVMValueRef) -> any LLVM.EmittedValue {
			EmittedStructPointerValue(type: self, ref: ref)
		}
	}

	struct StructInstanceValue: LLVM.IRValue {
		public var type: LLVM.StructType
	}
}
