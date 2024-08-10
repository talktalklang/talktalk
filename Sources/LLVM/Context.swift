//
//  Context.swift
//
//
//  Created by Pat Nakajima on 7/16/24.
//
import C_LLVM

public extension LLVM {
	class Context {
		let ref: LLVMContextRef
		let isOwned: Bool

		public static var global: Context {
			Context(ref: LLVMGetGlobalContext())
		}

		private init(ref: LLVMContextRef) {
			self.ref = ref
			self.isOwned = false
		}

		public init() {
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
