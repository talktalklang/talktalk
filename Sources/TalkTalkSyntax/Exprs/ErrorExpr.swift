//
//  ErrorExpr.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

public protocol ErrorExpr: Expr {
	var message: String { get }
}

public struct ErrorExprSyntax: ErrorExpr {
	public var message: String
	public let location: SourceLocation

	public init(message: String, location: SourceLocation) {
		self.message = message
		self.location = location
	}

	public func accept<V: Visitor>(_ visitor: V, _ scope: V.Context) -> V.Value {
		visitor.visit(self, scope)
	}
}
