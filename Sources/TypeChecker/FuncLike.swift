//
//  FuncLike.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/26/24.
//

import TalkTalkCore

// Used for being able to handle func and init decls with the same code
protocol FuncLike: Syntax {
	var params: ParamsExprSyntax { get }
	var body: BlockStmtSyntax { get }
	var typeDecl: TypeExprSyntax? { get }
	var name: Token? { get }
}

extension FuncExprSyntax: FuncLike {}
extension MethodDeclSyntax: FuncLike {
	var typeDecl: TypeExprSyntax? {
		returns
	}

	var name: Token? {
		nameToken
	}
}
extension InitDeclSyntax: FuncLike {
	var typeDecl: TypeExprSyntax? {
		nil
	}

	var name: Token? {
		nil
	}
}
