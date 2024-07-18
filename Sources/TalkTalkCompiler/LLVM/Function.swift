//
//  Function.swift
//
//
//  Created by Pat Nakajima on 7/16/24.
//
import C_LLVM
import TalkTalkTyper

enum VariableState: Equatable {
	static func ==(lhs: VariableState, rhs: VariableState) -> Bool {
		switch lhs {
		case .declared:
			if case .declared = rhs {
				return true
			}
		case .defined(let value):
			if case let .defined(other) = rhs {
				return value.hashValue == other.hashValue
			}
		case .allocated(let value):
			if case let .allocated(other) = rhs {
				return value.hashValue == other.hashValue
			}
		}

		return false
	}

	case declared, allocated(LLVM.StackValue), defined(any LLVM.IRValue)
}

extension LLVM {
	class Function {
		let type: FunctionType
		let ref: LLVMValueRef
		var parameters: [String: VariableState] = [:]
		var locals: [String: VariableState] = [:]

		init(type: FunctionType, ref: LLVMValueRef) {
			self.type = type
			self.ref = ref
		}

		func allocate(name: String, for type: TypedValue, in builder: Builder) -> StackValue {
			let type = type.llvmType(in: builder.module.context)
			let ref = inEntry(builder: builder) {
				LLVMBuildAlloca(
					builder.ref,
					type.ref,
					name
				)
			}

			return StackValue(ref: ref, type: type)
		}

		func inEntry(builder: Builder, perform: () -> LLVMValueRef) -> LLVMValueRef {
			let oldPosition = LLVMGetInsertBlock(builder.ref)
			let entryBlock = LLVMGetEntryBasicBlock(ref)
			LLVMPositionBuilderAtEnd(builder.ref, entryBlock)
			let ret = perform()
			LLVMPositionBuilderAtEnd(builder.ref, oldPosition)
			return ret
		}
	}
}
