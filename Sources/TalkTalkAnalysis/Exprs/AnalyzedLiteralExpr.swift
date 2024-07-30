//
//  AnalyzedLiteralExpr.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

import TalkTalkSyntax

public struct AnalyzedLiteralExpr: AnalyzedExpr, LiteralExpr {
	public var type: ValueType
	let expr: LiteralExpr

	public var value: LiteralValue { expr.value }
	public var location: SourceLocation { expr.location }

	public func accept<V: Visitor>(_ visitor: V, _ scope: V.Context) -> V.Value {
		visitor.visit(self, scope)
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) -> V.Value where V: AnalyzedVisitor {
		visitor.visit(self, scope)
	}
}