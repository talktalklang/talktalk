//
//  StmtSyntax.swift
//
//
//  Created by Pat Nakajima on 7/8/24.
//
public struct StmtSyntax: Syntax {
	public let start: Token
	public let end: Token

	public var description: String {
		"stmt?"
	}

	public var debugDescription: String {
		"stmt"
	}

	public func accept<Visitor: ASTVisitor>(_ visitor: inout Visitor) -> Visitor.Value {
		visitor.visit(self)
	}
}
