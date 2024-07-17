//
//  IntType.swift
//
//
//  Created by Pat Nakajima on 7/16/24.
//
import C_LLVM

extension LLVM {
	class IntType: LLVMType {
		let width: Int
		let ref: LLVMTypeRef

		init(width: Int, context: Context) {
			assert([1, 8, 16, 32, 64, 128].contains(width), "invalid int width, not in 1, 8, 16, 32, 64, 128")

			self.width = width
			self.ref = LLVMIntTypeInContext(context.ref, UInt32(width))
		}

		func constant(_ int: Int) -> IntValue {
			let constRef = LLVMConstInt(ref, UInt64(int), 0)!
			return IntValue(ref: constRef)
		}
	}

	class IntValue: LLVM.IRValue {
		let ref: LLVMValueRef

		init(ref: LLVMValueRef) {
			self.ref = ref
		}
	}
}

extension LLVMType where Self == LLVM.IntType {
	static func i1(_ context: LLVM.Context) -> LLVM.IntType {
		LLVM.IntType(width: 1, context: context)
	}

	static func i8(_ context: LLVM.Context) -> LLVM.IntType {
		LLVM.IntType(width: 8, context: context)
	}

	static func i16(_ context: LLVM.Context) -> LLVM.IntType {
		LLVM.IntType(width: 16, context: context)
	}

	static func i32(_ context: LLVM.Context) -> LLVM.IntType {
		LLVM.IntType(width: 32, context: context)
	}

	static func i64(_ context: LLVM.Context) -> LLVM.IntType {
		LLVM.IntType(width: 64, context: context)
	}
}
