//
//  JIT.swift
//
//
//  Created by Pat Nakajima on 7/17/24.
//
import C_LLVM

public extension LLVM {
	class JIT {
		public init() {
			// Initialize LLVM
			LLVMInitializeNativeTarget()
			LLVMInitializeNativeAsmPrinter()
			LLVMInitializeNativeAsmParser()
		}

		public func execute(module: LLVM.Module) -> Int? {
			var engine: LLVMExecutionEngineRef?
			var error: UnsafeMutablePointer<Int8>?
			LLVMCreateExecutionEngineForModule(&engine, module.ref, &error)

			// Get the function to execute
			let function = LLVMGetNamedFunction(module.ref, "main")

			// Execute the function
			let result = LLVMRunFunction(engine, function, 0, nil)

			// Get the return value
			let resultAsUnt64 = LLVMGenericValueToInt(result, 1)
			return Int(Int32(bitPattern: UInt32(truncatingIfNeeded: resultAsUnt64)))
		}
	}
}
