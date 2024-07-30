//
//  DeclBlockExpr.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/28/24.
//

public protocol DeclBlockExpr: Expr {
	var decls: [any Decl] { get }
}

public struct DeclBlockExprSyntax: DeclBlockExpr {
	public var decls: [any Decl]
	public let location: SourceLocation

	public init(decls: [any Decl], location: SourceLocation) {
		self.decls = decls
		self.location = location
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) -> V.Value where V : Visitor {
		visitor.visit(self, scope)
	}
}
