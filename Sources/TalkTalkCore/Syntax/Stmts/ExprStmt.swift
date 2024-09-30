//
//  ExprStmt.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/12/24.
//

public protocol ExprStmt: Stmt {
	var expr: any Expr { get }
}

public struct ExprStmtSyntax: ExprStmt {
	public var id: SyntaxID
	public var expr: any Expr
	public let location: SourceLocation
	public var children: [any Syntax] {
		[expr]
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: Visitor {
		try visitor.visit(self, scope)
	}
}
