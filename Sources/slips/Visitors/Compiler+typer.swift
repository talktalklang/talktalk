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
		switch expr {
		case let expr as FuncExpr:
			let functionType = LLVM.FunctionType(
				name: expr.name,
				returnType: getTypeOf(expr: expr.body.last!, context: context),
				parameterTypes: (0 ..< expr.params.params.count).map { _ in .i32 },
				isVarArg: false
			)

			return LLVM.TypePointer(type: functionType)
		case is LiteralExpr:
			return .i32
		case let expr as VarExpr:
			return context.environment.type(of: expr.name) ?? .i1 // TODO: Do better
		case is AddExpr:
			return .i32
		default:
			fatalError()
		}
	}
}
