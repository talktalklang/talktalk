//
//  Boxed.swift
//
//
//  Created by Pat Nakajima on 7/14/24.
//
@propertyWrapper public class Boxed<T> {
	var value: T?

	public var wrappedValue: T? {
		get {
			value
		}

		set {
			value = newValue
		}
	}

	init(value: T?) {
		self.value = value
	}
}
