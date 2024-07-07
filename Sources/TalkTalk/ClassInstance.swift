//
//  ClassInstance.swift
//
//
//  Created by Pat Nakajima on 7/7/24.
//
final class ClassInstance: Hashable, Equatable {
	static func == (lhs: ClassInstance, rhs: ClassInstance) -> Bool {
		lhs.klass == rhs.klass && lhs.fields == rhs.fields
	}

	let klass: Class
	private var fields: [String: Value]

	init(klass: Class, fields: [String: Value]) {
		self.klass = klass
		self.fields = fields
	}

	func hash(into hasher: inout Hasher) {
		hasher.combine(klass)
		hasher.combine(fields)
	}

	@inline(__always)
	func get(_ property: String) -> Value? {
		fields[property]
	}

	@inline(__always)
	func set(_ property: String, _ value: Value) {
		fields[property] = value
	}
}
