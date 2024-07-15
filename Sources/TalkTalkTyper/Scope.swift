//
//  Scope.swift
//  
//
//  Created by Pat Nakajima on 7/15/24.
//
class Scope {
	var parent: Scope?
	var locals: [String: TypedValue] = [:]
	var types: [String: ValueType] = [:]

	init(parent: Scope? = nil) {
		self.parent = parent
	}

	var depth: Int {
		(parent?.depth ?? -1) + 1
	}

	func lookup(identifier: String) -> TypedValue? {
		locals[identifier] ?? parent?.lookup(identifier: identifier)
	}

	func lookup(type: String) -> ValueType? {
		types[type] ?? parent?.lookup(type: type)
	}
}
