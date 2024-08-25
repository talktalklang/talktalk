//
//  IdentifierExpr.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/6/24.
//

public protocol IdentifierExpr: Expr {
	var name: String { get }
}

public struct IdentifierExprSyntax: IdentifierExpr {
	public var id: SyntaxID
	public var name: String
	public var location: SourceLocation

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: Visitor {
		try visitor.visit(self, scope)
	}

	public init(id: SyntaxID, name: String, location: SourceLocation) {
		self.id = id
		self.name = name
		self.location = location
	}

	public var children: [any Syntax] { [] }
}
