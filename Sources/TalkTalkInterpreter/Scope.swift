//
//  Scope.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

public class Scope {
	var parent: Scope?
	var locals: [String: Value] = [:]

	init(parent: Scope? = nil) {
		self.parent = parent
	}

	func define(_ name: String, _ value: Value) -> Value {
		locals[name] = value
		return value
	}

	func lookup(_ name: String) -> Value {
		if let local = locals[name] {
			return local
		}

		if case let .instance(instance) = locals["self"],
		   let property = instance.properties[name]
		{
			return property
		}

		if name == "print" {
			return .builtin("print")
		}

		return parent?.lookup(name) ?? .error("undefined variable: \(name)")
	}
}
