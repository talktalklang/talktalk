//
//  Compiler+main.swift
//  Slips
//
//  Created by Pat Nakajima on 7/25/24.
//

import LLVM

extension Compiler {
	// TODO: This could probably go into the LLVM package?
	func main(in builder: LLVM.Builder, body: () -> any LLVM.IRValue) {
		let mainType = LLVM.FunctionType(
			name: "main",
			returnType: .i32,
			parameterTypes: [],
			isVarArg: false,
			envStructType: nil
		)

		_ = builder.define(mainType, parameterNames: [], envStruct: nil) {
			if let retval = body() as? LLVM.IRValueRef {
				_ = builder.emit(return: .raw(retval.ref))
			}
		}
	}
}
