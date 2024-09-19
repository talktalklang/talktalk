//
//  Environment.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/25/24.
//

import TalkTalkSyntax

class Environment {
	var types: [SyntaxID: InferenceResult] = [:]
	var functionStack: [[InferenceResult]] = []

	init(types: [SyntaxID: InferenceResult] = [:], functionStack: [[InferenceResult]] = []) {
		self.types = types
		self.functionStack = functionStack
	}

	subscript(_ syntax: any Syntax) -> InferenceResult? {
		get {
			types[syntax.id]
		}

		set {
			types[syntax.id] = newValue
		}
	}

	func childEnvironment() -> Environment {
		let types = types // Copy the types
		return Environment(types: types)
	}

	func trackingReturns(block: () throws -> Void) throws -> [InferenceResult] {
		functionStack.append([])
		try block()
		return functionStack.popLast() ?? []
	}

	func trackReturn(_ result: InferenceResult) {
		if functionStack.indices.contains(functionStack.count - 1) {
			functionStack[functionStack.count - 1].append(result)
		}
	}

	func extend(_ syntax: any Syntax, with: InferenceResult) {
		if types[syntax.id] != nil {
			return
		}

		types[syntax.id] = with
	}

	func lookupVariable(named name: String) -> InferenceType? {
		for (_, type) in types {
			if case let .type(.typeVar(variable)) = type, variable.name == name {
				return .typeVar(variable)
			}

			if case let .type(.instantiatable(type)) = type, type.name == name {
				return .instantiatable(type)
			}

			if case let .scheme(scheme) = type, scheme.name == name {
				return scheme.type
			}
		}

		return nil
	}
}
