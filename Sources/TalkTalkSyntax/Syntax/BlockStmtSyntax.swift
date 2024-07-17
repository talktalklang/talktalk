//
//  BlockStmtSyntax.swift
//
//
//  Created by Pat Nakajima on 7/10/24.
//
public struct BlockStmtSyntax: Syntax, Stmt {
	public let start: Token
	public let end: Token

	public let decls: [any Decl]

	public static func == (lhs: Self, rhs: Self) -> Bool {
		lhs.hashValue == rhs.hashValue
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(start)
		hasher.combine(end)
		hasher.combine(decls.map(\.hashValue))
	}

	public var isEmpty: Bool {
		decls.isEmpty
	}

	public func accept<Visitor: ASTVisitor>(
		_ visitor: Visitor,
		context: Visitor.Context
	) -> Visitor.Value {
		visitor.visit(self, context: context)
	}
}
