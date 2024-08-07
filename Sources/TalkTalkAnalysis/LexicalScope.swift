//
//  LexicalScope.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/7/24.
//

import TalkTalkSyntax

public class LexicalScope {
	public var scope: StructType
	var type: ValueType
	var expr: any Expr

	init(scope: StructType, type: ValueType, expr: any Expr) {
		self.scope = scope
		self.type = type
		self.expr = expr
	}
}
