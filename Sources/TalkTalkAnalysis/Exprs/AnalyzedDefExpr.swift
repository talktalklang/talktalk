//
//  AnalyzedDefExpr.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

import TalkTalkSyntax

public struct AnalyzedDefExpr: AnalyzedExpr, DefExpr {
	public var value: any Expr { expr.value }
	
	public var typeAnalyzed: ValueType
	let expr: DefExpr

	public var receiver: any Expr { expr.receiver }
	public var receiverAnalyzed: any Expr
	public var location: SourceLocation { expr.location }
	public var children: [any Syntax] { expr.children }

	public var valueAnalyzed: any AnalyzedExpr
	public var analyzedChildren: [any AnalyzedSyntax] { [valueAnalyzed] }
	public let environment: Environment

	public func accept<V: Visitor>(_ visitor: V, _ scope: V.Context) throws -> V.Value {
		try visitor.visit(self, scope)
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: AnalyzedVisitor {
		try visitor.visit(self, scope)
	}
}
