//
//  AST.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

public struct VariadicExpr: Expr {
	public let op: Symbol
	public let operands: [any Expr]

	static func error(_ token: Token) -> Expr {
		ErrorExpr()
	}

	public init(op: Symbol, operands: [Expr]) {
		self.op = op
		self.operands = operands
	}
}
