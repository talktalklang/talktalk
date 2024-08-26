//
//  AnalyzedInitDecl.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/8/24.
//

import TalkTalkBytecode
import TalkTalkSyntax

public struct AnalyzedInitDecl: AnalyzedDecl, InitDecl {
	public let wrapped: InitDeclSyntax

	public let symbol: Symbol
	public let typeID: TypeID
	public var environment: Environment
	public var parametersAnalyzed: AnalyzedParamsExpr
	public var bodyAnalyzed: AnalyzedDeclBlock
	public var analyzedChildren: [any AnalyzedSyntax] {
		[parametersAnalyzed, bodyAnalyzed]
	}

	public var initToken: Token { wrapped.initToken }
	public var params: any ParamsExpr { wrapped.params }
	public var body: BlockStmtSyntax { wrapped.body }
	public var location: SourceLocation { wrapped.location }
	public var children: [any Syntax] { wrapped.children }

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: AnalyzedVisitor {
		try visitor.visit(self, scope)
	}

	public func accept<V>(_ visitor: V, _ context: V.Context) throws -> V.Value where V: TalkTalkSyntax.Visitor {
		try visitor.visit(wrapped, context)
	}
}
