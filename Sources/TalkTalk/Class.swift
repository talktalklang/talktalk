//
//  Class.swift
//
//
//  Created by Pat Nakajima on 7/7/24.
//
final class Class: Hashable {
	static func == (lhs: Class, rhs: Class) -> Bool {
		lhs.name == rhs.name
	}

	let name: String
	var hasInitializer = false
	var methods: [String: Closure]

	init(name: String, methods: [String: Closure] = [:]) {
		self.name = name
		self.methods = methods
	}

	func hash(into hasher: inout Hasher) {
		hasher.combine(name)
	}

	func lookup(method: String) -> Closure? {
		methods[method]
	}

	func define(method: Closure, as name: String) {
		if name == "init" {
			self.hasInitializer = true
		}

		methods[name] = method
	}
}
