//
//  Scope.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

public class Scope {
	let parent: Scope?
	var locals: [String: Value] = [:]

	init(parent: Scope? = nil) {
		self.parent = parent
	}

	func define(_ name: String, _ value: Value) -> Value {
		locals[name] = value
		return value
	}

	func lookup(_ name: String) -> Value {
		return locals[name] ?? .none
	}
}
