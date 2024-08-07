//
//  DeclBlockExpr.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/28/24.
//

public protocol DeclBlockExpr: Expr {
	var decls: [any Syntax] { get }
}

public struct DeclBlockExprSyntax: DeclBlockExpr {
	public var decls: [any Syntax]
	public let location: SourceLocation
	public var children: [any Syntax] { decls }

	public init(decls: [any Syntax], location: SourceLocation) {
		self.decls = decls
		self.location = location
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V : Visitor {
		try visitor.visit(self, scope)
	}
}
