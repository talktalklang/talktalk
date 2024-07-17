//
//  Context.swift
//  
//
//  Created by Pat Nakajima on 7/16/24.
//
import C_LLVM

extension LLVM {
	class Context {
		let ref: LLVMContextRef
		let isOwned: Bool

		static let global = Context(ref: LLVMGetGlobalContext())

		private init(ref: LLVMContextRef) {
			self.ref = ref
			self.isOwned = false
		}

		init() {
			self.ref = LLVMContextCreate()
			self.isOwned = true
		}

		deinit {
			if isOwned {
				LLVMContextDispose(ref)
			}
		}
	}
}
