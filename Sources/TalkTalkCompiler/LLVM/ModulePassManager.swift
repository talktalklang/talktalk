//
//  ModulePassManager.swift
//
//
//  Created by Pat Nakajima on 7/18/24.
//
import C_LLVM

extension LLVM {
	class ModulePassManager {
		let module: Module
		let ref: LLVMPassManagerRef

		init(module: Module) {
			self.module = module
			self.ref = LLVMCreateFunctionPassManagerForModule(module.ref)
		}

		func run() {
			let options = LLVMCreatePassBuilderOptions()
			LLVMPassBuilderOptionsSetLoopUnrolling(options, .true)

			var targetRef: LLVMTargetRef?
			var targetErr: UnsafeMutablePointer<Int8>?
			let tripleRef = LLVMGetDefaultTargetTriple()
			LLVMGetTargetFromTriple(tripleRef, &targetRef, &targetErr)

			if let targetErr {
				fatalError(String(cString: targetErr))
			}

			let cpu = LLVMGetHostCPUName()
			var features: [String] = []
			let optLevel = LLVMCodeGenLevelDefault
			let reloc = LLVMRelocDefault
			let model = LLVMCodeModelDefault
			let targetMachineRef = features.withUnsafeMutableBufferPointer {
				LLVMCreateTargetMachine(
					targetRef,
					tripleRef,
					cpu,
					$0.baseAddress,
					optLevel,
					reloc,
					model
				)
			}

			var passes = "default<O3>"
			withUnsafeBytes(of: &passes) {
				let err = LLVMRunPasses(
					module.ref,
					$0.baseAddress,
					targetMachineRef,
					options
				)

				if let err {
					let msg = LLVMGetErrorMessage(err)!
					fatalError(String(cString: msg))
				}
			}
		}
	}
}
