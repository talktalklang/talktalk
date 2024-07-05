//
//  Closure.swift
//
//
//  Created by Pat Nakajima on 7/4/24.
//
class Closure: Hashable, Equatable {
	static func == (lhs: Closure, rhs: Closure) -> Bool {
		lhs.function == rhs.function
	}

	var function: Function
	var upvalues: [Value?]

	init(function: Function, upvalues _: [Value] = []) {
		self.function = function
		self.upvalues = [Value?](repeating: nil, count: function.upvalueCount)
	}

	func hash(into hasher: inout Swift.Hasher) {
		hasher.combine(function)
	}
}
