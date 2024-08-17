//
//  TypeExpr.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/11/24.
//

public protocol TypeExpr: Expr {
	var identifier: Token { get }
	var genericParams: (any GenericParams)? { get }
}

public struct TypeExprSyntax: TypeExpr {
	public var identifier: Token
	public var genericParams: (any GenericParams)?
	public var location: SourceLocation
	public var errors: [String] = []
	public var children: [any Syntax] {
		if let genericParams { [genericParams] } else { [] }
	}

	public func accept<V>(_ visitor: V, _ context: V.Context) throws -> V.Value where V: Visitor {
		try visitor.visit(self, context)
	}
}
