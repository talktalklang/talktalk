//
//  ClosureType.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/1/24.
//

import C_LLVM

public extension LLVM {
	struct ClosureType: IRType, Callable {
		public typealias V = Closure

		public let functionType: FunctionType
		private let structType: StructType

		public init(functionType: FunctionType, captureTypes: [any IRType]) {
			self.functionType = functionType
			self.structType = LLVM.StructType(
				name: functionType.name + ".closure",
				 types: captureTypes,
				 offsets: [:],
				 namedTypeRef: nil,
				 vtable: nil
			 )
		}

		public var captureTypes: [any IRType] {
			Array(structType.types)
		}

		public init(functionType: FunctionType, structType: StructType) {
			self.functionType = functionType
			self.structType = structType
		}

		public func typeRef(in builder: LLVM.Builder) -> LLVMTypeRef {
			builder.capturesStruct(name: functionType.name + ".closure.type", functionType: functionType, types: captureTypes)
		}
		
		public func emit(ref: LLVMValueRef) -> any LLVM.EmittedValue {
			EmittedClosureValue(type: self, ref: ref)
		}
	}

	struct EmittedClosureValue: EmittedValue {
		public var type: LLVM.ClosureType

		// ref is a pointer to a closure
		public var ref: LLVMValueRef

		public init(type: LLVM.ClosureType, ref: LLVMValueRef) {
			self.type = type
			self.ref = ref
		}

		public var functionType: FunctionType {
			type.functionType
		}
	}

	struct Closure: IRValue {
		public var type: LLVM.ClosureType
		public var functionType: FunctionType
		public var captures: [(name: String, pointer: any StoredPointer)]

		public init(type: LLVM.ClosureType, functionType: FunctionType, captures: [(name: String, pointer: any StoredPointer)]) {
			self.type = type
			self.functionType = functionType
			self.captures = captures
		}

		public func loadCapture(at index: Int) -> any EmittedValue {
			VoidValue()
		}
	}
}
