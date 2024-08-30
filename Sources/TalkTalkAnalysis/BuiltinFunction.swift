//
//  BuiltinFunction.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/30/24.
//

import TypeChecker
import TalkTalkSyntax

extension BuiltinFunction {
	func binding(in env: Environment) -> Environment.Binding {
		.init(name: name, expr: IdentifierExprSyntax(id: -10, name: name, location: [.synthetic(.identifier)]), type: type)
	}
}
