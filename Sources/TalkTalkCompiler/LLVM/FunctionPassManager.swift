//
//  FunctionPassManager.swift
//  
//
//  Created by Pat Nakajima on 7/18/24.
//

import C_LLVM

extension LLVM {
	class FunctionPassManager {
		let module: Module

		init(module: Module) {
			self.module = module
		}

		func run(on function: Function) {
			let options = LLVMCreatePassBuilderOptions()

			let ref = LLVMCreateFunctionPassManagerForModule(module.ref)

			LLVMPassBuilderOptionsSetLoopUnrolling(ref, .true)
			LLVMPassBuilderOptionsSetLoopInterleaving(ref, .true)

			LLVMDumpValue(function.ref)

			LLVMInitializeFunctionPassManager(ref)

			LLVMDisposePassBuilderOptions(options)
			LLVMDisposePassManager(ref)

			LLVMDumpValue(function.ref)
		}
	}
}
