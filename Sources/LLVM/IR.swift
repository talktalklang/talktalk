//
//  IR.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

public extension LLVM {
	protocol IR {}
}

public extension LLVM.IR {
	var isPointer: Bool { false }
}
