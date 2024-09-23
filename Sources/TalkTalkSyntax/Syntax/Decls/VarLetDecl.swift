//
//  VarLetDecl.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/15/24.
//

public protocol VarLetDecl: Decl, Stmt {
	var name: String { get }
	var nameToken: Token { get }
	var isStatic: Bool { get }
	var typeExpr: TypeExprSyntax? { get }
	var value: (any Expr)? { get }
}

public extension VarLetDecl {
	var semanticLocation: SourceLocation? {
		[
			nameToken,
		]
	}
}
