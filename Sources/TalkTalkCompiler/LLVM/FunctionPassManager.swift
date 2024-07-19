//
//  FunctionPassManager.swift
//  
//
//  Created by Pat Nakajima on 7/18/24.
//

import C_LLVM

extension LLVM {
	class FunctionPassManager {
		let ref: LLVMPassManagerRef

		init(module: Module) {
			self.ref = LLVMCreateFunctionPassManagerForModule(module.ref)

			let options = LLVMCreatePassBuilderOptions()
		}
	}
}
