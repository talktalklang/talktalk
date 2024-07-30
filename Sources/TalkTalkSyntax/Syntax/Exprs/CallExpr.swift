//
//  CallExpr.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

public struct Argument {
	public let label: String?
	public let value: any Expr
}

public protocol CallExpr: Expr {
	var callee: any Expr { get }
	var args: [Argument] { get }
}

public struct CallExprSyntax: CallExpr {
	public let callee: any Expr
	public let args: [Argument]
	public let location: SourceLocation

	public func accept<V: Visitor>(_ visitor: V, _ scope: V.Context) -> V.Value {
		visitor.visit(self, scope)
	}
}
