//
//  IntType.swift
//
//
//  Created by Pat Nakajima on 7/16/24.
//
import C_LLVM

extension LLVM {
	class IntType: LLVMType {
		static func ==(lhs: IntType, rhs: IntType) -> Bool {
			lhs.width == rhs.width
		}

		let width: Int
		let ref: LLVMTypeRef

		init(width: Int, context: Context) {
			assert([1, 8, 16, 32, 64, 128].contains(width), "invalid int width, not in 1, 8, 16, 32, 64, 128")

			self.width = width
			self.ref = LLVMIntTypeInContext(context.ref, UInt32(width))
		}

		func constant(_ int: Int) -> IntValue {
			let constRef = LLVMConstInt(ref, UInt64(bitPattern: Int64(int)), 1)!
			return IntValue(ref: constRef)
		}

		func hash(into hasher: inout Hasher) {
			hasher.combine(width)
			hasher.combine(ref)
		}
	}

	class IntValue: LLVM.IRValue {
		static func ==(lhs: IntValue, rhs: IntValue) -> Bool {
			lhs.ref == rhs.ref
		}

		let ref: LLVMValueRef

		init(ref: LLVMValueRef) {
			self.ref = ref
		}

		func hash(into hasher: inout Hasher) {
			hasher.combine(ref)
		}
	}
}

extension LLVMType where Self == LLVM.IntType {
	static func i1(_ context: LLVM.Context = .global) -> LLVM.IntType {
		LLVM.IntType(width: 1, context: context)
	}

	static func i8(_ context: LLVM.Context = .global) -> LLVM.IntType {
		LLVM.IntType(width: 8, context: context)
	}

	static func i16(_ context: LLVM.Context = .global) -> LLVM.IntType {
		LLVM.IntType(width: 16, context: context)
	}

	static func i32(_ context: LLVM.Context = .global) -> LLVM.IntType {
		LLVM.IntType(width: 32, context: context)
	}

	static func i64(_ context: LLVM.Context = .global) -> LLVM.IntType {
		LLVM.IntType(width: 64, context: context)
	}
}

extension LLVM.IRValue where Self == LLVM.IntValue {
	static func i1(_ val: Int, in context: LLVM.Context = .global) -> LLVM.IntValue {
		LLVM.IntType(width: 1, context: context).constant(val)
	}

	static func i8(_ val: Int, in context: LLVM.Context = .global) -> LLVM.IntValue {
		LLVM.IntType(width: 8, context: context).constant(val)
	}

	static func i16(_ val: Int, in context: LLVM.Context = .global) -> LLVM.IntValue {
		LLVM.IntType(width: 16, context: context).constant(val)
	}

	static func i32(_ val: Int, in context: LLVM.Context = .global) -> LLVM.IntValue {
		LLVM.IntType(width: 32, context: context).constant(val)
	}

	static func i64(_ val: Int, in context: LLVM.Context = .global) -> LLVM.IntValue {
		LLVM.IntType(width: 64, context: context).constant(val)
	}
}
