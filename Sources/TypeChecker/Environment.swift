//
//  Environment.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/25/24.
//

import TalkTalkSyntax

class Environment {
	var types: [SyntaxID: InferenceResult] = [:]
	var functionStack: [Set<InferenceResult>] = []

	init(types: [SyntaxID : InferenceResult] = [:], functionStack: [Set<InferenceResult>] = []) {
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
		let types = self.types // Copy the types
		return Environment(types: types)
	}

	func trackingReturns(block: () throws -> Void) throws -> Set<InferenceResult> {
		functionStack.append([])
		try block()
		return functionStack.popLast()!
	}

	func trackReturn(_ result: InferenceResult) {
		if functionStack.indices.contains(functionStack.count-1) {
			functionStack[functionStack.count-1].insert(result)
		}
	}

	func extend(_ syntax: any Syntax, with: InferenceResult) {
		if types[syntax.id] != nil, types[syntax.id] != with {
			fatalError("trying to override syntax")
		}

		types[syntax.id] = with
	}

	func lookupVariable(named name: String) -> InferenceType? {
		for (_, type) in types {
			if case let .type(.typeVar(variable)) = type, variable.name == name {
				return .typeVar(variable)
			}

			if case let .type(.structType(structType)) = type, structType.name == name {
				return .structType(structType)
			}

			if case let .scheme(scheme) = type, scheme.name == name {
				return scheme.type
			}
		}

		return nil
	}
}
