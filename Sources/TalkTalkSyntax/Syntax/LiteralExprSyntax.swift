//
//  LiteralSyntax.swift
//  
//
//  Created by Pat Nakajima on 7/10/24.
//
public struct LiteralExprSyntax: Syntax, Expr {
	public enum Kind {
		case `true`, `false`, `nil`
	}

	public let position: Int
	public let length: Int
	public let kind: Kind

	public func accept<Visitor: ASTVisitor>(_ visitor: inout Visitor) -> Visitor.Value {
		visitor.visit(self)
	}

	public var description: String {
		switch kind {
		case .true:
			"true"
		case .false:
			"false"
		case .nil:
			"nil"
		}
	}
}
