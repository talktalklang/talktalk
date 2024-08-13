//
//  AnalyzedVarDecl.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/30/24.
//

import TalkTalkSyntax

public struct AnalyzedVarDecl: AnalyzedExpr, AnalyzedDecl, VarDecl {
	public let typeID: TypeID
	let expr: VarDecl
	public var analyzedChildren: [any AnalyzedSyntax] { [] }
	public let environment: Environment

	public var token: Token { expr.token }
	public var name: String { expr.name }
	public var typeDecl: String { expr.typeDecl }
	public var typeDeclToken: Token { expr.typeDeclToken }
	public var location: SourceLocation { expr.location }
	public var children: [any Syntax] { expr.children }

	public func accept<V: Visitor>(_ visitor: V, _ scope: V.Context) throws -> V.Value {
		try visitor.visit(self, scope)
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: AnalyzedVisitor {
		try visitor.visit(self, scope)
	}
}
