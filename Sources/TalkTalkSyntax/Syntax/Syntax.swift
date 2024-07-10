//
//  Syntax.swift
//
//
//  Created by Pat Nakajima on 7/8/24.
//
public protocol Syntax: CustomStringConvertible, CustomDebugStringConvertible {
	var position: Int { get }
	var length: Int { get }
}

public extension Syntax {
	func at<T: Syntax>(_ keyPath: KeyPath<Self, T>) -> T {
		self[keyPath: keyPath]
	}

	func `as`<T: Syntax>(_: T.Type) -> T? {
		if let cast = self as? T {
			return cast
		}

		return nil
	}

	func cast<T: Syntax>(_: T.Type) -> T {
		self as! T
	}
}
