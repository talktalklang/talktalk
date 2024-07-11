//
//  AssignmentExpr.swift
//
//
//  Created by Pat Nakajima on 7/10/24.
//
public struct AssignmentExpr: Syntax, Expr {
	public let position: Int
	public let length: Int
	public let lhs: any Expr
	public let rhs: any Expr

	public func accept<Visitor: ASTVisitor>(_ visitor: inout Visitor) -> Visitor.Value {
		visitor.visit(self)
	}
}
