//
//  AnalyzedCallExpr.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

import TalkTalkSyntax

public struct AnalyzedArgument {
	public let label: String?
	public let expr: any AnalyzedExpr
}

public struct AnalyzedCallExpr: AnalyzedExpr, CallExpr {
	public var type: ValueType
	let expr: CallExpr

	public var calleeAnalyzed: any AnalyzedExpr
	public var argsAnalyzed: [AnalyzedArgument]

	public var callee: any Expr { expr.callee }
	public var args: [CallArgument] { expr.args }
	public var location: SourceLocation { expr.location }

	public func accept<V: Visitor>(_ visitor: V, _ scope: V.Context) throws -> V.Value {
		try visitor.visit(self, scope)
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: AnalyzedVisitor {
		try visitor.visit(self, scope)
	}
}
