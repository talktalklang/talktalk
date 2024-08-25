//
//  ImportStmt.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/29/24.
//

public protocol ImportStmt: Stmt {
	var token: Token { get }
	var module: any IdentifierExpr { get }
}

public struct ImportStmtSyntax: ImportStmt {
	public var id: SyntaxID
	public var token: Token
	public var module: any IdentifierExpr

	public let location: SourceLocation
	public let children: [any Syntax] = []

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: Visitor {
		try visitor.visit(self, scope)
	}
}
