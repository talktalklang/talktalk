//
//  AnalyzedFuncExpr.swift
//
//
//  Created by Pat Nakajima on 7/24/24.
//

import TalkTalkSyntax

public struct AnalyzedFuncExpr: AnalyzedExpr, FuncExpr, Decl, AnalyzedDecl {
	public let typeID: TypeID
	let expr: FuncExpr

	public let analyzedParams: AnalyzedParamsExpr
	public let bodyAnalyzed: AnalyzedBlockStmt
	public let returnType: TypeID
	public let environment: Environment
	public let analysisErrors: [AnalysisError]
	public var analyzedChildren: [any AnalyzedSyntax] {
		[bodyAnalyzed]
	}

	public var name: Token?
	public var funcToken: Token { expr.funcToken }
	public var params: ParamsExpr { expr.params }
	public var typeDecl: (any TypeExpr)? { expr.typeDecl }
	public var body: any BlockStmt { expr.body }
	public var i: Int { expr.i }
	public var location: SourceLocation { expr.location }
	public var children: [any Syntax] { expr.children }

	public init(
		type: TypeID,
		expr: FuncExpr,
		analyzedParams: AnalyzedParamsExpr,
		bodyAnalyzed: AnalyzedBlockStmt,
		analysisErrors: [AnalysisError],
		returnType: TypeID,
		environment: Environment
	) {
		self.name = expr.name
		self.typeID = type
		self.expr = expr
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
		try visitor.visit(self, scope)
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: AnalyzedVisitor {
		try visitor.visit(self, scope)
	}
}
