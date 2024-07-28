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
	public let name: String

	init(params: ParamsExpr, body: [any Expr], i: Int, name: String? = nil) {
		self.params = params
		self.body = body
		self.i = i
		self.name = name ?? "_fn_\(params.params.map(\.name).joined(separator: "_"))_\(body.map(\.description).joined(separator: "_"))_\(i)"
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) -> V.Value where V: Visitor {
		visitor.visit(self, scope)
	}
}
