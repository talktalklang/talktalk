//
//  PropertyAccessExpr.swift
//
//
//  Created by Pat Nakajima on 7/11/24.
//
public struct PropertyAccessExpr: Expr, Syntax {
	public let start: Token
	public let end: Token

	public var receiver: any Expr
	public var property: IdentifierSyntax

	public static func ==(lhs: Self, rhs: Self) -> Bool {
		lhs.hashValue == rhs.hashValue
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(start)
		hasher.combine(end)
		hasher.combine(receiver)
		hasher.combine(property)
	}

	public func accept<Visitor: ASTVisitor>(
		_ visitor: inout Visitor,
		context: Visitor.Context
	) -> Visitor.Value {
		visitor.visit(self, context: context)
	}
}
