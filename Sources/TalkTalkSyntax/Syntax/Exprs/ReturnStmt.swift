//
//  ReturnExpr.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/31/24.
//

public protocol ReturnStmt: Stmt {
	var returnToken: Token { get }
	var value: (any Expr)? { get }
}

public struct ReturnStmtSyntax: ReturnStmt {
	public var id: SyntaxID
	public var returnToken: Token
	public var location: SourceLocation
	public var value: (any Expr)?
	public var children: [any Syntax] {
		if let value { [value] } else { [] }
	}

	public init(id: SyntaxID, returnToken: Token, location: SourceLocation, value: (any Expr)? = nil) {
		self.id = id
		self.returnToken = returnToken
		self.location = location
		self.value = value
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: Visitor {
		try visitor.visit(self, scope)
	}
}
