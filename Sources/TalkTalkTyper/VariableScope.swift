//
//  Scope.swift
//
//
//  Created by Pat Nakajima on 7/15/24.
//
class VariableScope {
	var parent: VariableScope?
	var locals: [String: TypedValue] = [:]
	var types: [String: ValueType] = [:]

	init(parent: VariableScope? = nil) {
		self.parent = parent
	}

	var depth: Int {
		(parent?.depth ?? -1) + 1
	}

	func lookup(identifier: String, withParents: Bool = false) -> TypedValue? {
		if let value = locals[identifier] {
			return value
		}

		if !withParents {
			return nil
		}

		return parent?.lookup(identifier: identifier, withParents: withParents)
	}

	func lookup(type: String) -> ValueType? {
		types[type] ?? parent?.lookup(type: type)
	}
}
