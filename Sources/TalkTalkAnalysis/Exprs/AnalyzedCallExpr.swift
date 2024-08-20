//
//  AnalyzedCallExpr.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

import TalkTalkSyntax

public struct AnalyzedArgument: Syntax, AnalyzedSyntax {
	public var typeID: TypeID { expr.typeID }
	public var environment: Environment
	public var analyzedChildren: [any AnalyzedSyntax] { expr.analyzedChildren }
	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: AnalyzedVisitor {
		try expr.accept(visitor, scope)
	}

	public var location: SourceLocation { expr.location }
	public var children: [any Syntax] { expr.children }
	public func accept<V>(_ visitor: V, _ context: V.Context) throws -> V.Value where V: Visitor {
		try expr.accept(visitor, context)
	}

	public let label: Token?
	public let expr: any AnalyzedExpr
}

public struct AnalyzedCallExpr: AnalyzedExpr, CallExpr {
	public let typeID: TypeID
	let expr: CallExpr

	public var calleeAnalyzed: any AnalyzedExpr
	public var argsAnalyzed: [AnalyzedArgument]
	public var analyzedChildren: [any AnalyzedSyntax] {
		[calleeAnalyzed] + argsAnalyzed.map(\.expr)
	}

	public var analysisErrors: [AnalysisError]
	public let environment: Environment

	public var callee: any Expr { expr.callee }
	public var args: [CallArgument] { expr.args }
	public var location: SourceLocation { expr.location }
	public var children: [any Syntax] { expr.children }

	public func accept<V: Visitor>(_ visitor: V, _ scope: V.Context) throws -> V.Value {
		try visitor.visit(self, scope)
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: AnalyzedVisitor {
		try visitor.visit(self, scope)
	}
}
