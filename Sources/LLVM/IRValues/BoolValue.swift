//
//  BoolValue.swift
//  LLVM
//
//  Created by Pat Nakajima on 7/25/24.
//

import C_LLVM

public extension LLVM {
	struct BoolValue: IRValue {
		public typealias T = BoolType
		public var type: LLVM.BoolType
	}
}
