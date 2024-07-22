//
//  IR.swift
//  
//
//  Created by Pat Nakajima on 7/22/24.
//

public extension LLVM {
	protocol IR {
		func asLLVM<T>() -> T
	}
}
