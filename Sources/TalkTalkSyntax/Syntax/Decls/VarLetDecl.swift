//
//  VarLetDecl.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/15/24.
//

public protocol VarLetDecl: Decl, Stmt {
	var name: String { get }
	var nameToken: Token { get }
	var typeExpr: (any TypeExpr)? { get }
}
