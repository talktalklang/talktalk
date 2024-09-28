//
//  AnalyzedFuncExpr.swift
//
//
//  Created by Pat Nakajima on 7/24/24.
//

import TalkTalkBytecode
import TalkTalkCore

public struct AnalyzedFuncExpr: AnalyzedExpr, FuncExpr, Decl, AnalyzedDecl {
	public let inferenceType: InferenceType
	public let wrapped: FuncExprSyntax

	public let symbol: Symbol
	public let analyzedParams: AnalyzedParamsExpr
	public let bodyAnalyzed: AnalyzedBlockStmt
	public let returnType: InferenceType
	public let environment: Environment
	public let analysisErrors: [AnalysisError]
	public var analyzedChildren: [any AnalyzedSyntax] {
		[bodyAnalyzed]
	}

	public var name: Token?
	public var funcToken: Token { wrapped.funcToken }
	public var params: ParamsExpr { wrapped.params }
	public var typeDecl: (any TypeExpr)? { wrapped.typeDecl }
	public var body: BlockStmtSyntax { wrapped.body }
	public var isStatic: Bool { wrapped.isStatic }

	public init(
		symbol: Symbol,
		type: InferenceType,
		wrapped: FuncExprSyntax,
		analyzedParams: AnalyzedParamsExpr,
		bodyAnalyzed: AnalyzedBlockStmt,
		analysisErrors: [AnalysisError],
		returnType: InferenceType,
		environment: Environment
	) {
		self.symbol = symbol
		self.name = wrapped.name
		self.inferenceType = type
		self.wrapped = wrapped
		self.analyzedParams = analyzedParams
		self.bodyAnalyzed = bodyAnalyzed
		self.analysisErrors = analysisErrors
		self.returnType = returnType
		self.environment = environment
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: Visitor {
		try visitor.visit(wrapped, scope)
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: AnalyzedVisitor {
		try visitor.visit(self, scope)
	}
}
