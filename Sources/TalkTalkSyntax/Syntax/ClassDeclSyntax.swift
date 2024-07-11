//
//  ClassDeclSyntax.swift
//
//
//  Created by Pat Nakajima on 7/11/24.
//
public struct ClassDeclSyntax: Decl, Syntax {
	public var position: Int
	public var length: Int
	public var name: IdentifierSyntax
	public var body: BlockStmtSyntax

	public func accept<Visitor: ASTVisitor>(_ visitor: inout Visitor) -> Visitor.Value {
		visitor.visit(self)
	}

	public var description: String {
		"class \(name.description) {}"
	}
}
