//
//  IfStmtSyntax.swift
//
//
//  Created by Pat Nakajima on 7/10/24.
//
public struct IfStmtSyntax: Syntax, Stmt {
	public let start: Token
	public let end: Token
	public var condition: any Expr
	public var `then`: BlockStmtSyntax
	public var `else`: BlockStmtSyntax?

	public static func == (lhs: Self, rhs: Self) -> Bool {
		lhs.hashValue == rhs.hashValue
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(start)
		hasher.combine(end)
		hasher.combine(condition)
		hasher.combine(self.then)
		hasher.combine(self.else)
	}

	public func accept<Visitor: ASTVisitor>(
		_ visitor: Visitor,
		context: Visitor.Context
	) -> Visitor.Value {
		visitor.visit(self, context: context)
	}
}
