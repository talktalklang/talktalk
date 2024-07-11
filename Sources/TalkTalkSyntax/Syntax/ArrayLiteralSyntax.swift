//
//  ArrayLiteralSyntax.swift
//  
//
//  Created by Pat Nakajima on 7/11/24.
//
public struct ArrayLiteralSyntax: Expr, Syntax {
	public var position: Int
	public var length: Int
	public var elements: ArgumentListSyntax
	
	public var description: String {
		"[\(elements.description)]"
	}

	public func accept<Visitor: ASTVisitor>(_ visitor: inout Visitor) -> Visitor.Value {
		visitor.visit(self)
	}
}
