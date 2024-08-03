//
//  Value.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

import TalkTalkAnalysis

public struct StructType {
	var name: String?
	var properties: [String: ValueType]
	var methods: [String: AnalyzedFuncExpr]
}

public struct StructInstance {
	var type: StructType
	var properties: [String: Value]

	public func resolve(property: String) -> Value? {
		if let value = properties[property] {
			return value
		}

		if let funcExpr = type.methods[property] {
			return .method(funcExpr, self)
		}

		return nil
	}
}

public indirect enum Value: Equatable, Comparable {
	case int(Int),
	     bool(Bool),
			 string(String),
	     none,
	     error(String),
	     fn(Closure),
	     method(AnalyzedFuncExpr, StructInstance),
	     `struct`(StructType),
	     instance(StructInstance),
	     `return`(Value),
	     builtin(String)

	public static func < (lhs: Value, rhs: Value) -> Bool {
		switch lhs {
		case let .int(int):
			guard case let .int(rhs) = rhs else {
				fatalError()
			}

			return int < rhs
		default:
			fatalError()
		}
	}

	public static func == (lhs: Value, rhs: Value) -> Bool {
		switch (lhs, rhs) {
		case let (.string(lhs), .string(rhs)):
			return lhs == rhs
		case let (.int(lhs), .int(rhs)):
			return lhs == rhs
		case let (.bool(lhs), .bool(rhs)):
			return lhs == rhs
		case let (.fn(lhs), .fn(rhs)):
			return lhs.funcExpr.i == rhs.funcExpr.i
		default:
			return false
		}
	}

	public func negate() -> Value {
		switch self {
		case let .int(int):
			.int(-int)
		case let .bool(bool):
			.bool(!bool)
		default:
			.error("Cannot negate \(self)")
		}
	}

	public var isTruthy: Bool {
		switch self {
		case .int:
			true
		case .string(_):
			true
		case .method:
			true
		case .struct(_), .instance:
			true
		case .builtin:
			true
		case let .bool(bool):
			bool
		case .none:
			false
		case .error:
			false
		case .fn:
			false
		case .return:
			fatalError()
		}
	}

	public func add(_ other: Value) -> Value {
		switch self {
		case let .int(int):
			guard case let .int(other) = other else {
				return .error("Cannot add \(other) to \(self)")
			}

			return .int(int + other)
		default:
			return .error("Cannot add \(other) to \(self)")
		}
	}

	public func minus(_ other: Value) -> Value {
		switch self {
		case let .int(int):
			guard case let .int(other) = other else {
				return .error("Cannot add \(other) to \(self)")
			}

			return .int(int - other)
		default:
			return .error("Cannot add \(other) to \(self)")
		}
	}

	public func times(_ other: Value) -> Value {
		switch self {
		case let .int(int):
			guard case let .int(other) = other else {
				return .error("Cannot add \(other) to \(self)")
			}

			return .int(int * other)
		default:
			return .error("Cannot add \(other) to \(self)")
		}
	}

	public func div(_ other: Value) -> Value {
		switch self {
		case let .int(int):
			guard case let .int(other) = other else {
				return .error("Cannot add \(other) to \(self)")
			}

			return .int(int / other)
		default:
			return .error("Cannot add \(other) to \(self)")
		}
	}
}
