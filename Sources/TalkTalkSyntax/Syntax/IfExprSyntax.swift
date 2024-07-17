//
//  IfExprSyntax.swift
//
//
//  Created by Pat Nakajima on 7/14/24.
//
public struct IfExprSyntax: Syntax, Expr {
	public let start: Token
	public let end: Token
	public var condition: any Expr
	public var thenBlock: BlockStmtSyntax
	public var elseBlock: BlockStmtSyntax

	public static func == (lhs: Self, rhs: Self) -> Bool {
		lhs.hashValue == rhs.hashValue
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(start)
		hasher.combine(end)
		hasher.combine(condition)
		hasher.combine(thenBlock)
		hasher.combine(elseBlock)
	}

	public func accept<Visitor: ASTVisitor>(
		_ visitor: Visitor,
		context: Visitor.Context
	) -> Visitor.Value {
		visitor.visit(self, context: context)
	}
}
