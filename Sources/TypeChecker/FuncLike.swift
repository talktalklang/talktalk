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
	var typeDecl: (any TypeExpr)? { get }
	var name: Token? { get }
}

extension FuncExprSyntax: FuncLike {}
extension InitDeclSyntax: FuncLike {
	var typeDecl: (any TypeExpr)? {
		nil
	}

	var name: Token? {
		nil
	}
}
