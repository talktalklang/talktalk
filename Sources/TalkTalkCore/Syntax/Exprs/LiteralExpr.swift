//
//  LiteralExpr.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

public enum LiteralValue: Equatable {
	case int(Int), bool(Bool), string(String), `nil`
}

public protocol LiteralExpr: Expr {
	var value: LiteralValue { get }
}

public struct LiteralExprSyntax: LiteralExpr {
	public var id: SyntaxID
	public let value: LiteralValue
	public let location: SourceLocation
	public var children: [any Syntax] { [] }

	public init(id: SyntaxID, value: LiteralValue, location: SourceLocation) {
		self.id = id
		self.value = value
		self.location = location
	}

	public func accept<V: Visitor>(_ visitor: V, _ scope: V.Context) throws -> V.Value {
		try visitor.visit(self, scope)
	}
}
