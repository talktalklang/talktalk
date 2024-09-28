//
//  Closure.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/24/24.
//

import TalkTalkCore

public class Closure {
	let funcExpr: FuncExpr
	let environment: Scope

	init(funcExpr: FuncExpr, environment: Scope) {
		self.funcExpr = funcExpr
		self.environment = environment
	}
}
