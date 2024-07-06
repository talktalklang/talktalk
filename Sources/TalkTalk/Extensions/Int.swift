//
//  Int.swift
//
//
//  Created by Pat Nakajima on 7/1/24.
//

extension Int {
	var placeholder: String {
		String(repeating: " ", count: "\(self)".count - 1) + "|"
	}
}

// Implement postfix increment
postfix func ++(value: inout Int) -> Int {
		defer { value += 1 }
		return value
}

// Implement postfix decrement
postfix func --(value: inout Int) -> Int {
		defer { value -= 1 }
		return value
}
