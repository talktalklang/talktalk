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
	var expr: any Syntax

	init(scope: StructType, type: ValueType, expr: any Syntax) {
		self.scope = scope
		self.type = type
		self.expr = expr
	}
}
