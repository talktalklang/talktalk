//
//  PropertyAccessExpr.swift
//
//
//  Created by Pat Nakajima on 7/11/24.
//
public struct PropertyAccessExpr: Expr, Syntax {
	public var position: Int
	public var length: Int

	public var receiver: any Expr
	public var property: IdentifierSyntax

	public func accept<Visitor: ASTVisitor>(_ visitor: inout Visitor) -> Visitor.Value {
		visitor.visit(self)
	}
}
