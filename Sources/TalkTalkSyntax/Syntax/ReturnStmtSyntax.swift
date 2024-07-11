//
//  ReturnStmtSyntax.swift
//
//
//  Created by Pat Nakajima on 7/10/24.
//
public struct ReturnStmtSyntax: Syntax, Stmt {
	public let position: Int
	public let length: Int
	public var value: any Expr

	public func accept<Visitor: ASTVisitor>(_ visitor: inout Visitor) -> Visitor.Value {
		visitor.visit(self)
	}

	public var description: String {
		"return \(value.description)"
	}
}
