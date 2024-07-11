//
//  StmtSyntax.swift
//
//
//  Created by Pat Nakajima on 7/8/24.
//
public struct StmtSyntax: Syntax {
	public var position: Int
	public var length: Int

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
