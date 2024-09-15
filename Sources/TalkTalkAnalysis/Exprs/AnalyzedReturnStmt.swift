//
//  AnalyzedReturnStmt.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/31/24.
//

import TalkTalkSyntax

public struct AnalyzedReturnStmt: AnalyzedStmt, ReturnStmt {
	public let inferenceType: InferenceType
	public var analyzedChildren: [any AnalyzedSyntax] {
		if let valueAnalyzed { [valueAnalyzed] } else { [] }
	}

	public let environment: Environment

	public let wrapped: ReturnStmtSyntax

	public var returnToken: Token { wrapped.returnToken }
	public var value: (any Expr)? { wrapped.value }

	public var valueAnalyzed: (any AnalyzedExpr)?

	public func accept<V: Visitor>(_ visitor: V, _ scope: V.Context) throws -> V.Value {
		try visitor.visit(wrapped, scope)
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: AnalyzedVisitor {
		try visitor.visit(self, scope)
	}
}
