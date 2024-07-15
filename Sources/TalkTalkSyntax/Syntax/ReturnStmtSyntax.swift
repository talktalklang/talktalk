//
//  ReturnStmtSyntax.swift
//
//
//  Created by Pat Nakajima on 7/10/24.
//
public struct ReturnStmtSyntax: Syntax, Stmt {
	public let start: Token
	public let end: Token
	public var value: any Expr

	public static func == (lhs: Self, rhs: Self) -> Bool {
		lhs.hashValue == rhs.hashValue
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(start)
		hasher.combine(end)
		hasher.combine(value)
	}

	public func accept<Visitor: ASTVisitor>(
		_ visitor: inout Visitor,
		context: Visitor.Context
	) -> Visitor.Value {
		visitor.visit(self, context: context)
	}
}
