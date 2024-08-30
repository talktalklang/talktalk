//
//  ParamsExpr.swift
//
//
//  Created by Pat Nakajima on 7/24/24.
//

public protocol Param: Expr {
	var name: String { get }
	var type: (any TypeExpr)? { get }
}

public protocol ParamsExpr: Expr {
	var params: [any Param] { get }
}

public extension ParamsExpr {
	subscript(_ index: Int) -> Param {
		params[index]
	}

	var count: Int {
		params.count
	}
}

public extension Param where Self == ParamSyntax {
	static func synthetic(name: String) -> Param {
		ParamSyntax(id: -1, name: name, location: [.synthetic(.identifier)])
	}
}

public struct ParamSyntax: Param {
	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: Visitor {
		try visitor.visit(self, scope)
	}

	public var id: SyntaxID
	public let name: String
	public let type: (any TypeExpr)?
	public var location: SourceLocation
	public var children: [any Syntax] { [] }

	public init(id: SyntaxID, name: String, type: (any TypeExpr)? = nil, location: SourceLocation) {
		self.id = id
		self.name = name
		self.type = type
		self.location = location
	}
}

public struct ParamsExprSyntax: ParamsExpr {
	public var id: SyntaxID
	public var params: [any Param]
	public let location: SourceLocation
	public var children: [any Syntax] { params }

	public init(id: SyntaxID, params: [any Param], location: SourceLocation) {
		self.id = id
		self.params = params
		self.location = location
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: Visitor {
		try visitor.visit(self, scope)
	}
}
