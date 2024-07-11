//
//  BinaryExprSyntax.swift
//
//
//  Created by Pat Nakajima on 7/8/24.
//
public struct BinaryExprSyntax: Syntax, Expr {
	public let lhs: any Expr
	public let op: BinaryOperatorSyntax
	public let rhs: any Expr

	public var position: Int
	public var length: Int

	public var description: String {
		"\(lhs.description) \(op.description) \(rhs.description)"
	}

	public func accept<Visitor: ASTVisitor>(_ visitor: inout Visitor) -> Visitor.Value {
		visitor.visit(self)
	}
}
