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
		var functionTypes: [LLVMValueRef: FunctionType] = [:]

		init(name: String = "Hello", in context: Context) {
			self.name = name
			self.context = context
			self.ref = LLVMModuleCreateWithNameInContext(name, context.ref)
		}

		func function(from ref: LLVMValueRef) -> Function? {
			if let type = functionTypes[ref] {
				return Function(type: type, ref: ref)
			}

			return nil
		}

		func function(named name: String) -> Function? {
			if let fnref = LLVMGetNamedFunction(ref, name) {
				let type = functionTypes[fnref]!
				return Function(type: type, ref: fnref)
			}

			return nil
		}

		public func dump() {
			LLVMDumpModule(ref)
		}

		deinit {
			LLVMDisposeModule(ref)
		}
	}
}
