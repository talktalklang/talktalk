//
//  Compiler+main.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/25/24.
//

import LLVM

extension Compiler {
	// TODO: This could probably go into the LLVM package?
	func main(in builder: LLVM.Builder, body: () -> any LLVM.IRValue) throws {
		let mainType = LLVM.FunctionType(
			name: "main",
			returnType: .i32,
			parameterTypes: [],
			isVarArg: false,
			capturedTypes: []
		)

		let closure = builder.createClosurePointer(name: "main", functionType: mainType, captures: [])

		_ = try builder.define(mainType, parameterNames: [], closurePointer: closure) {
			if let retval = body() as? LLVM.IRValueRef {
				_ = builder.emit(return: .raw(retval.ref))
			}
		}
	}
}
