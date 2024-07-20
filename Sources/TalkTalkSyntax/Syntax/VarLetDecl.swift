//
//  VarLetDecl.swift
//  
//
//  Created by Pat Nakajima on 7/20/24.
//

public protocol VarLetDecl: Syntax, Decl {
	var variable: IdentifierSyntax { get }
	var typeDecl: TypeDeclSyntax? { get }
	var expr: (any Expr)? { get }
}
