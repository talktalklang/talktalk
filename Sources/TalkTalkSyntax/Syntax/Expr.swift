//
//  Expr.swift
//
//
//  Created by Pat Nakajima on 7/8/24.
//
public protocol Expr: Syntax {}

public extension Expr {
	func accept<Visitor>(_: inout Visitor) -> Visitor.Value where Visitor: ASTVisitor {
		fatalError("Unimplemented visitor")
	}
}
