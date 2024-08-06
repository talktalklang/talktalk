//
//  ReturnExpr.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/31/24.
//

public protocol ReturnExpr: Expr {
	var value: (any Expr)? { get }
}

public struct ReturnExprSyntax: ReturnExpr {
	public var location: SourceLocation
	public var value: (any Expr)?
	public var children: [any Syntax] {
		if let value { [value] } else { [] }
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V : Visitor {
		try visitor.visit(self, scope)
	}
}
