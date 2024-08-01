//
//  FuncExpr.swift
//
//
//  Created by Pat Nakajima on 7/24/24.
//

public protocol FuncExpr: Expr {
	var params: ParamsExpr { get }
	var body: any BlockExpr { get }
	var i: Int { get }
	var name: String? { get }
}

public extension FuncExpr {
	var autoname: String {
		"_fn_\(params.params.map(\.name).joined(separator: "_"))_\(i)"
	}
}

public struct FuncExprSyntax: FuncExpr, Decl {
	public let params: ParamsExpr
	public let body: any BlockExpr
	public let i: Int
	public let name: String?
	public let location: SourceLocation

	public init(params: ParamsExpr, body: any BlockExpr, i: Int, name: String? = nil, location: SourceLocation) {
		self.params = params
		self.body = body
		self.i = i
		self.name = name // ??
		self.location = location
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: Visitor {
		try visitor.visit(self, scope)
	}
}
