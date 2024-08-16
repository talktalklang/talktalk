//
//  VarLetDecl.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/15/24.
//

public protocol VarLetDecl: Decl, Stmt {
	var nameToken: Token { get }
}
