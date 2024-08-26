//
//  AnalyzedFuncExpr.swift
//
//
//  Created by Pat Nakajima on 7/24/24.
//

import TalkTalkBytecode
import TalkTalkSyntax

public struct AnalyzedFuncExpr: AnalyzedExpr, FuncExpr, Decl, AnalyzedDecl {
	public let typeID: TypeID
	public let wrapped: FuncExprSyntax

	public let symbol: Symbol
	public let analyzedParams: AnalyzedParamsExpr
	public let bodyAnalyzed: AnalyzedBlockStmt
	public let returnType: TypeID
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
	public var i: Int { wrapped.i }

	public init(
		symbol: Symbol,
		type: TypeID,
		wrapped: FuncExprSyntax,
		analyzedParams: AnalyzedParamsExpr,
		bodyAnalyzed: AnalyzedBlockStmt,
		analysisErrors: [AnalysisError],
		returnType: TypeID,
		environment: Environment
	) {
		self.symbol = symbol
		self.name = wrapped.name
		self.typeID = type
		self.wrapped = wrapped
		self.analyzedParams = analyzedParams
		self.bodyAnalyzed = bodyAnalyzed
		self.analysisErrors = analysisErrors
		self.returnType = returnType
		self.environment = environment
	}

	public var typeAnalyzed: ValueType {
		guard case let .function(
			name,
			returning,
			_,
			captures
		) = typeID.type() else {
			fatalError("unreachable")
		}

		let updatedParams = analyzedParams.paramsAnalyzed.map {
			ValueType.Param(name: $0.name, typeID: $0.typeID)
		}

		return .function(name, returning, updatedParams, captures)
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: Visitor {
		try visitor.visit(wrapped, scope)
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: AnalyzedVisitor {
		try visitor.visit(self, scope)
	}
}
