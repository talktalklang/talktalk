//
//  InitDeclSyntax.swift
//
//
//  Created by Pat Nakajima on 7/11/24.
//
public struct InitDeclSyntax: Decl, Syntax {
	public var position: Int
	public var length: Int

	var parameters: ParameterListSyntax
	var body: BlockStmtSyntax

	public func accept<Visitor: ASTVisitor>(_ visitor: inout Visitor) -> Visitor.Value {
		visitor.visit(self)
	}

	public var description: String {
		"init(\(parameters.description) {}"
	}
}
