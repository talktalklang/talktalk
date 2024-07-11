//
//  IfStmtSyntax.swift
//  
//
//  Created by Pat Nakajima on 7/10/24.
//
public struct IfStmtSyntax: Syntax, Stmt {
	public var position: Int
	public var length: Int
	public var condition: any Expr
	public var body: BlockStmtSyntax

	public func accept<Visitor: ASTVisitor>(_ visitor: inout Visitor) -> Visitor.Value {
		visitor.visit(self)
	}
	
	public var description: String {
		"""
		if \(condition.description) \(body)
		"""
	}
}