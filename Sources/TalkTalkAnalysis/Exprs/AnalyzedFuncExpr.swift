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
	public let bodyAnalyzed: AnalyzedBlockExpr
	public let returnsAnalyzed: (any AnalyzedSyntax)?
	public let environment: Environment
	public var analyzedChildren: [any AnalyzedSyntax] {
		[bodyAnalyzed]
	}

	public var name: Token?
	public var funcToken: Token { expr.funcToken }
	public var params: ParamsExpr { expr.params }
	public var body: any BlockExpr { expr.body }
	public var i: Int { expr.i }
	public var location: SourceLocation { expr.location }
	public var children: [any Syntax] { expr.children }

	public init(
		type: TypeID,
		expr: FuncExpr,
		analyzedParams: AnalyzedParamsExpr,
		bodyAnalyzed: AnalyzedBlockExpr,
		returnsAnalyzed: (any AnalyzedSyntax)?,
		environment: Environment
	) {
		self.name = expr.name
		self.typeID = type
		self.expr = expr
		self.analyzedParams = analyzedParams
		self.bodyAnalyzed = bodyAnalyzed
		self.returnsAnalyzed = returnsAnalyzed
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
