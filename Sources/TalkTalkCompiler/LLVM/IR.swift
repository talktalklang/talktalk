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

extension Array: LLVM.IR where Element == any LLVM.IR {
	public func asLLVM<T>() -> T {
		self as! T
	}
}
