//
//  FunctionType.swift
//  LLVM
//
//  Created by Pat Nakajima on 7/25/24.
//

import C_LLVM

public extension LLVM {
	struct FunctionType: IRType, Callable {
		public typealias V = Function

		public var name: String
		public let returnType: any IRType
		public let parameterTypes: [any IRType]
		public let isVarArg: Bool
		public let capturedTypes: [any IRType]

		public init(name: String, returnType: any IRType, parameterTypes: [any IRType], isVarArg: Bool, capturedTypes: [any IRType]) {
			self.name = name

			self.returnType = if let fnType = returnType as? FunctionType, !fnType.capturedTypes.isEmpty {
				ClosureType(functionType: fnType, captureTypes: fnType.capturedTypes)
			} else {
				returnType
			}

			self.parameterTypes = parameterTypes
			self.isVarArg = isVarArg
			self.capturedTypes = capturedTypes
		}

		public func asReturnType(in builder: LLVM.Builder) -> LLVMTypeRef {
			LLVMPointerType(typeRef(in: builder), 0)
		}

		public func emit(ref: LLVMValueRef) -> any LLVM.EmittedValue {
			EmittedFunctionValue(type: self, ref: ref)
		}

		public func typeRef(in builder: LLVM.Builder) -> LLVMTypeRef {
			var parameters: [LLVMTypeRef?] = parameterTypes.map { $0.typeRef(in: builder) }
			return parameters.withUnsafeMutableBufferPointer {
				LLVMFunctionType(
					returnType.asReturnType(in: builder),
					$0.baseAddress,
					UInt32($0.count),
					isVarArg ? 1 : 0
				)
			}
		}
	}
}
