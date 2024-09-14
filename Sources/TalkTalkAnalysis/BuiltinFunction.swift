//
//  BuiltinFunction.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/30/24.
//

import TalkTalkSyntax
import TypeChecker

extension BuiltinFunction {
	func binding(in _: Environment) -> Environment.Binding {
		.init(name: name, location: [.synthetic(.identifier)], type: type)
	}
}
