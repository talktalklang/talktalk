//
//  BinaryExpr.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/28/24.
//

public enum BinaryOperator: String {
	case plus = "+",
			 equalEqual = "==",
			 bangEqual = "!=",
			 less = "<",
			 lessEqual = "<=",
			 greater = ">",
			 greaterEqual = ">=",
			 minus = "-",
			 star = "*",
			 slash = "/"
}

public protocol BinaryExpr: Expr {
	var lhs: any Expr { get }
	var rhs: any Expr { get }
	var op: BinaryOperator { get }
}

public struct BinaryExprSyntax: BinaryExpr {
	public let lhs: any Expr
	public let rhs: any Expr
	public let op: BinaryOperator
	public let location: SourceLocation

	public func accept<V>(_ visitor: V, _ scope: V.Context) -> V.Value where V: Visitor {
		visitor.visit(self, scope)
	}
}
