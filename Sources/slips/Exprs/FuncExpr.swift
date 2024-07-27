//
//  FuncExpr.swift
//
//
//  Created by Pat Nakajima on 7/24/24.
//

public protocol FuncExpr: Expr {
	var params: ParamsExpr { get }
	var body: [any Expr] { get }
	var i: Int { get }
	var name: String { get }
}

public struct FuncExprSyntax: FuncExpr {
	public let params: ParamsExpr
	public let body: [any Expr]
	public let i: Int

	public var name: String {
		"_fn_\(params.names.map(\.name).joined(separator: "_"))_\(i)"
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) -> V.Value where V: Visitor {
		visitor.visit(self, scope)
	}
}
