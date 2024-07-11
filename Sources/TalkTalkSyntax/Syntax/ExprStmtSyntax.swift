//
//  Untitled.swift
//
//
//  Created by Pat Nakajima on 7/8/24.
//
public struct ExprStmtSyntax: Syntax, Stmt {
	public let position: Int
	public let length: Int
	public let expr: any Expr

	public var description: String {
		expr.description
	}

	public func accept<Visitor: ASTVisitor>(_ visitor: inout Visitor) -> Visitor.Value {
		visitor.visit(self)
	}
}
