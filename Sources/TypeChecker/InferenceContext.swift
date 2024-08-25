//
//  Context.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/25/24.
//

typealias VariableID = Int

enum InferenceError {
	case undefinedVariable(String)
	case unknownError(any Error)
}

class InferenceContext {
	var lastVariableID = 0
	var errors: [InferenceError] = []
	var environment: Environment

	init(lastVariableID: Int = 0, environment: Environment) {
		self.lastVariableID = lastVariableID
		self.environment = environment
	}

	func addError(_ inferenceError: InferenceError) {
		errors.append(inferenceError)
	}

	func freshVariable(_ name: String) -> TypeVariable {
		defer { lastVariableID += 1 }
		return TypeVariable(name, lastVariableID)
	}
}
