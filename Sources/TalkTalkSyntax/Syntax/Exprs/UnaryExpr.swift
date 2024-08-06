//
//  UnaryExpr.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/2/24.
//

public protocol UnaryExpr: Expr {
	var op: Token.Kind { get }
	var expr: any Expr { get }
}

public struct UnaryExprSyntax: UnaryExpr {
	public let op: Token.Kind
	public let expr: any Expr
	public var location: SourceLocation
	public var children: [any Syntax] { [expr] }

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V : Visitor {
		try visitor.visit(self, scope)
	}
}
