//
//  ParamsExpr.swift
//
//
//  Created by Pat Nakajima on 7/24/24.
//

public protocol Param: Expr {
	var name: String { get }
}

public protocol ParamsExpr: Expr {
	var params: [any Param] { get }
}

public extension ParamsExpr {
	subscript(_ index: Int) -> Param {
		params[index]
	}
}

public struct ParamSyntax: Param {
	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V : Visitor {
		try visitor.visit(self, scope)
	}
	
	public let name: String
	public var location: SourceLocation
	public var children: [any Syntax] { [] }

	public init(name: String, location: SourceLocation) {
		self.name = name
		self.location = location
	}
}

public struct ParamsExprSyntax: ParamsExpr {
	public var params: [any Param]
	public let location: SourceLocation
	public var children: [any Syntax] { params }

	public init(params: [any Param], location: SourceLocation) {
		self.params = params
		self.location = location
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: Visitor {
		try visitor.visit(self, scope)
	}
}
