//
//  JIT.swift
//
//
//  Created by Pat Nakajima on 7/17/24.
//
import C_LLVM

public extension LLVM {
	class JIT {
		public init() {}

		public func execute(module: LLVM.Module, optimize: Bool = false) -> Int? {
			LLVMInitializeNativeTarget()
			LLVMInitializeNativeAsmParser()
			LLVMInitializeNativeAsmPrinter()

			var message: UnsafeMutablePointer<Int8>?
			LLVMVerifyModule(module.ref, LLVMPrintMessageAction, &message)

			if let message, String(cString: message) != "" {
				defer { LLVMDisposeMessage(message) }
				print("Module Dump: ------------------------------")
				LLVMDumpModule(module.ref)
				print("-------------------------------------------")
				fatalError("Error compiling:\n\(String(cString: message))")
			}

			var engine: LLVMExecutionEngineRef?
			var error: UnsafeMutablePointer<Int8>?
			LLVMCreateExecutionEngineForModule(&engine, module.ref, &error)


			// Get the function to execute
			let function = LLVMGetNamedFunction(module.ref, "main")

			if optimize {
				LLVM.ModulePassManager(module: module).run()
			}

			// Execute the function
			let result = LLVMRunFunction(engine, function, 0, nil)

			// Get the return value
			let resultAsUnt64 = LLVMGenericValueToInt(result, 1)
			return Int(Int32(bitPattern: UInt32(truncatingIfNeeded: resultAsUnt64)))
		}
	}
}
