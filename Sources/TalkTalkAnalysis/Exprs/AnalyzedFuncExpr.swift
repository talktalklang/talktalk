//
//  AnalyzedFuncExpr.swift
//
//
//  Created by Pat Nakajima on 7/24/24.
//

import TalkTalkSyntax

public struct AnalyzedFuncExpr: AnalyzedExpr, FuncExpr, Decl, AnalyzedDecl {
	public var type: ValueType
	let expr: FuncExpr

	public let analyzedParams: AnalyzedParamsExpr
	public let bodyAnalyzed: AnalyzedBlockExpr
	public let returnsAnalyzed: (any AnalyzedExpr)?
	public let environment: Analyzer.Environment

	public var params: ParamsExpr { expr.params }
	public var body: any BlockExpr { expr.body }
	public var i: Int { expr.i }
	public var location: SourceLocation { expr.location }

	public var name: String? {
		expr.name
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) -> V.Value where V: Visitor {
		visitor.visit(self, scope)
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) -> V.Value where V: AnalyzedVisitor {
		visitor.visit(self, scope)
	}
}
