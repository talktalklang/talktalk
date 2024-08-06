//
//  DefExpr.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

public protocol DefExpr: Expr {
	var name: Token { get }
	var value: any Expr { get }
}

public struct DefExprSyntax: DefExpr {
	public let name: Token
	public let nameSyntax: IdentifierExprSyntax
	public let value: any Expr
	public let location: SourceLocation
	public var children: [any Syntax] { [nameSyntax, value] }

	public func accept<V: Visitor>(_ visitor: V, _ scope: V.Context) throws -> V.Value {
		try visitor.visit(self, scope)
	}
}
