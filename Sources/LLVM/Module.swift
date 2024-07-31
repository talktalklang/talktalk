//
//  Module.swift
//
//
//  Created by Pat Nakajima on 7/16/24.
//
import C_LLVM

public extension LLVM {
	class Module {
		let context: Context
		let ref: LLVMModuleRef
		let name: String
		var functionTypes: [LLVMValueRef: any LLVM.IRType] = [:]

		public init(name: String, in context: Context) {
			self.name = name
			self.context = context
			self.ref = LLVMModuleCreateWithNameInContext(name, context.ref)
		}

		public func write(to path: String) {
			LLVMWriteBitcodeToFile(ref, path)
		}

		public func dump() {
			LLVMDumpModule(ref)
		}

		deinit {
			LLVMDisposeModule(ref)
		}
	}
}
