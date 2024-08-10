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
			structType.types
		}

		public init(functionType: FunctionType, structType: StructType) {
			self.functionType = functionType
			self.structType = structType
		}

		public func typeRef(in builder: LLVM.Builder) -> LLVMTypeRef {
			builder.capturesStruct(name: functionType.name + ".closure.ptr", functionType: functionType, types: captureTypes)
		}

		public func functionTypeRef(in builder: LLVM.Builder) -> LLVMTypeRef {
			var newParameterTypes = functionType.parameterTypes

			if !captureTypes.isEmpty {
				newParameterTypes.append(TypePointer(type: self))
			}

			let newReturnType = if let returnType = functionType.returnType as? ClosureType {
				TypePointer(type: returnType)
			} else {
				functionType.returnType
			}

			return FunctionType(
				name: functionType.name,
				returnType: newReturnType,
				parameterTypes: newParameterTypes,
				isVarArg: false,
				capturedTypes: captureTypes
			).typeRef(in: builder)
		}

		public func emit(ref: LLVMValueRef) -> any LLVM.EmittedValue {
			EmittedClosureValue(type: self, ref: ref)
		}

		public func asMethod(in context: LLVM.Context, on structType: LLVM.StructType) -> ClosureType {
			var newParameterTypes = functionType.parameterTypes
			let newName = "\(structType.name)_\(functionType.name)"

			newParameterTypes.insert(TypePointer(type: structType), at: 0)

			let functionType = FunctionType(
				name: newName,
				returnType: functionType.returnType,
				parameterTypes: newParameterTypes,
				isVarArg: false,
				capturedTypes: []
			)

			return ClosureType(functionType: functionType, structType: structType)
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
