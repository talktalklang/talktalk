//
//  Closure.swift
//
//
//  Created by Pat Nakajima on 7/4/24.
//
struct Closure: Hashable, Equatable {
	private final class Storage {
		var function: Function
		var upvalues: ContiguousArray<Value?>

		init(function: Function, upvalues: ContiguousArray<Value?>) {
			self.function = function
			self.upvalues = upvalues
			self.upvalues.reserveCapacity(16)
		}
	}

	static func == (lhs: Closure, rhs: Closure) -> Bool {
		lhs.function == rhs.function
	}

	private let storage: Storage

	var function: Function {
		get {
			storage.function
		}

		set {
			storage.function = newValue
		}
	}

	var upvalues: ContiguousArray<Value?> {
		get {
			storage.upvalues
		}

		set {
			storage.upvalues = newValue
		}
	}

	init(function: Function) {
		self.storage = Storage(function: function, upvalues: ContiguousArray(repeating: nil, count: function.upvalueCount))
	}

	func hash(into hasher: inout Swift.Hasher) {
		hasher.combine(function)
	}
}
