//
//  IfExpr.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

public protocol IfExpr: Expr {
	var ifToken: Token { get }
	var elseToken: Token? { get }
	var condition: any Expr { get }
	var consequence: any BlockStmt { get }
	var alternative: any BlockStmt { get }
}

public struct IfExprSyntax: IfExpr {
	public var ifToken: Token
	public var elseToken: Token?
	public let condition: any Expr
	public let consequence: any BlockStmt
	public let alternative: any BlockStmt
	public let location: SourceLocation
	public var children: [any Syntax] { [condition, consequence, alternative] }

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: Visitor {
		try visitor.visit(self, scope)
	}
}
