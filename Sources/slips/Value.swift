//
//  Value.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

public enum Value: Equatable {
	case int(Int), string(String), bool(Bool), none, error(String)

	public var isTruthy: Bool {
		switch self {
		case let .int(int):
			true
		case let .string(string):
			true
		case let .bool(bool):
			bool
		case .none:
			false
		case let .error(string):
			false
		}
	}

	public func add(_ other: Value) -> Value {
		switch self {
		case let .int(int):
			guard case let .int(other) = other else {
				return .error("Cannot add \(other) to \(self)")
			}

			return .int(int + other)
		case let .string(string):
			guard case let .string(other) = other else {
				return .error("Cannot add \(other) to \(self)")
			}

			return .string(string + other)
		default:
			return .error("Cannot add \(other) to \(self)")
		}
	}
}
