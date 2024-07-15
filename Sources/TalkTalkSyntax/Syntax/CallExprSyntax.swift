//
//  CallExprSyntax.swift
//
//
//  Created by Pat Nakajima on 7/10/24.
//
public struct CallExprSyntax: Syntax, Expr {
	public let start: Token
	public let end: Token
	public let callee: any Expr
	public let arguments: ArgumentListSyntax

	public static func == (lhs: Self, rhs: Self) -> Bool {
		lhs.hashValue == rhs.hashValue
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(start)
		hasher.combine(end)
		hasher.combine(callee)
		hasher.combine(arguments)
	}

	public func accept<Visitor: ASTVisitor>(
		_ visitor: inout Visitor,
		context: Visitor.Context
	) -> Visitor.Value {
		visitor.visit(self, context: context)
	}
}
