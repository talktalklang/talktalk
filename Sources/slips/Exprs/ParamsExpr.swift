//
//  ParamsExpr.swift
//
//
//  Created by Pat Nakajima on 7/24/24.
//

public protocol Param {
	var name: String { get }
}

public protocol ParamsExpr: Expr {
	var names: [any Param] { get }
}

public extension ParamsExpr {
	subscript(_ index: Int) -> Param {
		names[index]
	}
}

public struct ParamSyntax: Param {
	public let name: String
}

public struct ParamsExprSyntax: ParamsExpr {
	public var names: [any Param]

	public func accept<V>(_ visitor: V, _ scope: V.Context) -> V.Value where V: Visitor {
		visitor.visit(self, scope)
	}
}
