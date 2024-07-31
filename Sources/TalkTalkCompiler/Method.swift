//
//  Method.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/30/24.
//

import C_LLVM
import LLVM

struct MethodType: LLVM.IRType {
	typealias V = Method

	let calleeType: any LLVM.IRType
	let functionType: LLVM.FunctionType

	func typeRef(in context: LLVM.Context) -> LLVMTypeRef {
		var paramTypes: [LLVMTypeRef?] = [
			calleeType.typeRef(in: context)
		]

		for paramType in functionType.parameterTypes {
			paramTypes.append(paramType.typeRef(in: context))
		}

		return paramTypes.withUnsafeMutableBufferPointer {
			LLVMFunctionType(
				functionType.typeRef(in: context),
				$0.baseAddress,
				UInt32($0.count),
				.zero
			)
		}
	}

	func emit(ref: LLVMValueRef) -> any LLVM.EmittedValue {
		fatalError()
	}
}

struct Method: LLVM.IRValue, LLVM.EmittedValue {
	var type: MethodType
	var ref: LLVMValueRef

	init(type: MethodType, ref: LLVMValueRef) {
		self.type = type
		self.ref = ref
	}

	func buildCall(
		receiver: LLVM.EmittedStructPointerValue,
		args: [any LLVM.EmittedValue],
		builder: LLVM.Builder
	) -> any LLVM.EmittedValue {
		let parameterTypes: [any LLVM.IRType] = [receiver.type] + args.map { $0.type }
		var args: [LLVMValueRef?] = [receiver.ref] + args.map(\.ref)

		let functionType = LLVM.FunctionType(
			name: type.functionType.name,
			returnType: type.functionType.returnType,
			parameterTypes: parameterTypes,
			isVarArg: false,
			captures: nil
		)

		return builder.call(functionRef: ref, as: functionType, with: &args, returning: functionType.returnType)
	}
}
