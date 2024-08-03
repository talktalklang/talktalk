//
//  FixedWidthInteger.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/2/24.
//

// Implement postfix increment
@discardableResult public postfix func ++ (value: inout Int) -> Int {
	defer { value += 1 }
	return value
}

// Implement prefix increment
@discardableResult public prefix func ++ (value: inout Int) -> Int {
	value += 1
	return value
}

// Implement postfix decrement
@discardableResult public postfix func -- (value: inout Int) -> Int {
	defer { value -= 1 }
	return value
}

// Implement prefix decrement
@discardableResult public prefix func -- (value: inout Int) -> Int {
	value -= 1
	return value
}


// Implement postfix increment
@discardableResult public postfix func ++ (value: inout UInt64) -> UInt64 {
	defer { value += 1 }
	return value
}

// Implement prefix increment
@discardableResult public prefix func ++ (value: inout UInt64) -> UInt64 {
	value += 1
	return value
}

// Implement postfix decrement
@discardableResult public postfix func -- (value: inout UInt64) -> UInt64 {
	defer { value -= 1 }
	return value
}

// Implement prefix decrement
@discardableResult public prefix func -- (value: inout UInt64) -> UInt64 {
	value -= 1
	return value
}
