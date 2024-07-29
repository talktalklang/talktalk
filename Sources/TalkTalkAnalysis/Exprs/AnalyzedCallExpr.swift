//
//  AnalyzedCallExpr.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

import TalkTalkSyntax

public struct AnalyzedCallExpr: AnalyzedExpr, CallExpr {
	public var type: ValueType
	let expr: CallExpr

	public var calleeAnalyzed: any AnalyzedExpr
	public var argsAnalyzed: [any AnalyzedExpr]

	public var callee: any Expr { expr.callee }
	public var args: [any Expr] { expr.args }
	public var location: SourceLocation { expr.location }

	public func accept<V: Visitor>(_ visitor: V, _ scope: V.Context) -> V.Value {
		visitor.visit(self, scope)
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) -> V.Value where V: AnalyzedVisitor {
		visitor.visit(self, scope)
	}
}
