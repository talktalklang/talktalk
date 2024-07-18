//
//  Builder.swift
//
//
//  Created by Pat Nakajima on 7/16/24.
//
import C_LLVM

extension LLVM {
	class Builder {
		let module: Module
		let ref: LLVMBuilderRef

		init(module: Module) {
			self.module = module
			self.ref = LLVMCreateBuilderInContext(module.context.ref)
		}

		func addFunction(named name: String, _ functionType: FunctionType) -> Function? {
			if let ref = LLVMAddFunction(module.ref, name, functionType.ref) {
				module.functionTypes[ref] = functionType
				return Function(type: functionType, ref: ref)
			}

			return nil
		}
	}
}
