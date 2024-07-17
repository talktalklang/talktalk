//
//  Module.swift
//
//
//  Created by Pat Nakajima on 7/16/24.
//
import C_LLVM

extension LLVM {
	public class Module {
		let context: Context
		let ref: LLVMModuleRef
		let name: String

		init(name: String = "Hello", in context: Context) {
			self.name = name
			self.context = context
			self.ref = LLVMModuleCreateWithNameInContext(name, context.ref)
		}

		func dump() {
			LLVMDumpModule(ref)
		}

		deinit {
			LLVMDisposeModule(ref)
		}
	}
}
