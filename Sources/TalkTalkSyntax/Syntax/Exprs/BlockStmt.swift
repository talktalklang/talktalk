//
//  BlockStmt.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/28/24.
//

public protocol BlockStmt: Expr {
	var stmts: [any Stmt] { get }
}

public struct BlockStmtSyntax: BlockStmt {
	public var id: SyntaxID
	public var stmts: [any Stmt]
	public let location: SourceLocation
	public var children: [any Syntax] { stmts }

	public init(id: SyntaxID, stmts: [any Stmt], location: SourceLocation) {
		self.id = id
		self.stmts = stmts
		self.location = location
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: Visitor {
		try visitor.visit(self, scope)
	}
}
