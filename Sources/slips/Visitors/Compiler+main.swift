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
			isVarArg: false
		)

		let main = LLVM.Function(type: mainType, environment: .init())

		_ = builder.define(main, parameterNames: []) {
			if let retval = body() as? LLVM.IRValueRef {
				builder.emit(return: .raw(retval.ref))
			}
		}
	}
}
