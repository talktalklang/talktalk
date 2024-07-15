//
//  WhileStmtSyntax.swift
//
//
//  Created by Pat Nakajima on 7/10/24.
//
public struct WhileStmtSyntax: Syntax, Stmt {
	public let start: Token
	public let end: Token
	public var condition: any Expr
	public var body: BlockStmtSyntax

	public static func == (lhs: Self, rhs: Self) -> Bool {
		lhs.hashValue == rhs.hashValue
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(start)
		hasher.combine(end)
		hasher.combine(condition)
		hasher.combine(body)
	}

	public func accept<Visitor: ASTVisitor>(
		_ visitor: inout Visitor,
		context: Visitor.Context
	) -> Visitor.Value {
		visitor.visit(self, context: context)
	}
}
