//
//  BlockExpr.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/28/24.
//

public protocol BlockExpr: Expr {
	var exprs: [any Syntax] { get }
}

public struct BlockExprSyntax: BlockExpr {
	public var exprs: [any Syntax]
	public let location: SourceLocation
	public var children: [any Syntax] { exprs }

	public init(exprs: [any Syntax], location: SourceLocation) {
		self.exprs = exprs
		self.location = location
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V : Visitor {
		try visitor.visit(self, scope)
	}
}
