//
//  WhileExpr.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/28/24.
//

public protocol WhileStmt: Stmt {
	var whileToken: Token { get }
	var condition: any Expr { get }
	var body: any BlockStmt { get }
}

public struct WhileStmtSyntax: WhileStmt {
	public var whileToken: Token
	public var condition: any Expr
	public var body: any BlockStmt
	public let location: SourceLocation
	public var children: [any Syntax] { [condition, body] }

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V : Visitor {
		try visitor.visit(self, scope)
	}
}
