//
//  Compiler+typer.swift
//  Slips
//
//  Created by Pat Nakajima on 7/25/24.
//

import LLVM

extension Compiler {
	// Try to guess what the "type" of this expression is
	func getTypeOf(expr: any Expr, context: Context) -> any LLVM.IRType {
		fatalError()
	}
}
