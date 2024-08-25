//
//  Environment.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/25/24.
//

import TalkTalkSyntax

class Environment {
	private var types: [SyntaxID: InferenceResult] = [:]

	subscript(_ syntax: any Syntax) -> InferenceResult? {
		get {
			types[syntax.id]
		}

		set {
			types[syntax.id] = newValue
		}
	}

	func extend(_ syntax: any Syntax, with: InferenceResult) {
		types[syntax.id] = with
	}

	func lookupVariable(named name: String) -> InferenceType? {
		for (_, type) in types {
			if case let .type(.variable(variable)) = type, variable.name == name {
				return .variable(variable)
			}
		}

		return nil
	}
}
