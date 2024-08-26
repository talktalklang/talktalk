//
//  TypeExpr.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/11/24.
//

public protocol TypeExpr: Expr {
	var identifier: Token { get }
	var genericParams: [TypeExprSyntax] { get }
}

public struct TypeExprSyntax: TypeExpr {
	public var id: SyntaxID
	public var identifier: Token
	public var genericParams: [TypeExprSyntax]
	public var location: SourceLocation
	public var errors: [String] = []
	public var children: [any Syntax] {
		genericParams
	}

	public func accept<V>(_ visitor: V, _ context: V.Context) throws -> V.Value where V: Visitor {
		try visitor.visit(self, context)
	}
}
