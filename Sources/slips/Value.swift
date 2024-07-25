//
//  Value.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

public enum Value: Equatable {
	case int(Int), string(String), bool(Bool), none, error(String), fn(FuncExpr)

	public static func == (lhs: Value, rhs: Value) -> Bool {
		switch lhs {
		case let .int(int):
			guard case let .int(rhs) = rhs else {
				return false
			}

			return int == rhs
		case let .string(string):
			guard case let .string(rhs) = rhs else {
				return false
			}

			return string == rhs
		case let .bool(bool):
			guard case let .bool(rhs) = rhs else {
				return false
			}

			return bool == rhs
		case .none:
			return false
		case .error:
			guard case let .int(rhs) = rhs else {
				return false
			}

			return false
		case let .fn(fn):
			guard case let .fn(rhs) = rhs else {
				return false
			}

			return fn.body.map { $0.accept(Formatter(), Scope()) } == rhs.body.map { $0.accept(Formatter(), Scope()) }
		}
	}

	public var isTruthy: Bool {
		switch self {
		case .int:
			true
		case .string:
			true
		case let .bool(bool):
			bool
		case .none:
			false
		case .error:
			false
		case .fn:
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
