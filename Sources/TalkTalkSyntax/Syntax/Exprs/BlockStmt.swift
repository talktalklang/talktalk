//
//  BlockExpr.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/28/24.
//

public protocol BlockStmt: Expr {
	var stmts: [any Stmt] { get }
}

public struct BlockStmtSyntax: BlockStmt {
	public var stmts: [any Stmt]
	public let location: SourceLocation
	public var children: [any Syntax] { stmts }

	public init(stmts: [any Stmt], location: SourceLocation) {
		self.stmts = stmts
		self.location = location
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V : Visitor {
		try visitor.visit(self, scope)
	}
}
