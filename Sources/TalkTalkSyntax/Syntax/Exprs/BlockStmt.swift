//
//  BlockStmt.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/28/24.
//

public protocol BlockStmt: Stmt, Expr {
	var stmts: [any Stmt] { get }
	var params: ParamsExprSyntax? { get }
}

public struct BlockStmtSyntax: BlockStmt {
	public var id: SyntaxID
	public var stmts: [any Stmt]
	public let params: ParamsExprSyntax?
	public let location: SourceLocation
	public var children: [any Syntax] { stmts }

	public init(id: SyntaxID, stmts: [any Stmt], params: ParamsExprSyntax?, location: SourceLocation) {
		self.id = id
		self.stmts = stmts
		self.params = params
		self.location = location
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: Visitor {
		try visitor.visit(self, scope)
	}
}
