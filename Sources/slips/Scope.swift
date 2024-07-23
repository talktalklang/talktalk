//
//  Scope.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

public class Scope {
	var locals: [String: Value] = [:]

	func define(_ name: String, _ value: Value) -> Value {
		locals[name] = value
		return value
	}
}
