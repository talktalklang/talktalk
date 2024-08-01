//
//  ReturnExpr.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/31/24.
//

public protocol ReturnExpr: Expr {
	var value: (any Expr)? { get }
}

public struct ReturnExprSyntax: ReturnExpr {
	public var location: SourceLocation
	public var value: (any Expr)?

	public func accept<V>(_ visitor: V, _ scope: V.Context) -> V.Value where V : Visitor {
		visitor.visit(self, scope)
	}
}
