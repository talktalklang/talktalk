//
//  LexicalScope.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/7/24.
//

import TalkTalkSyntax

public class LexicalScope {
	public var scope: StructType
	var expr: any Syntax

	init(scope: StructType, expr: any Syntax) {
		self.scope = scope
		self.expr = expr
	}
}
