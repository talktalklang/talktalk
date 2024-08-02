//
//  IfExpr.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

public protocol IfExpr: Expr {
	var condition: any Expr { get }
	var consequence: any BlockExpr { get }
	var alternative: any BlockExpr { get }
}

public struct IfExprSyntax: IfExpr {
	public let condition: any Expr
	public let consequence: any BlockExpr
	public let alternative: any BlockExpr
	public let location: SourceLocation

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: Visitor {
		try visitor.visit(self, scope)
	}
}