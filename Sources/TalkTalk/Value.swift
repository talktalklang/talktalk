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

public enum Value: Equatable {
	case int(Int),
			 bool(Bool),
			 none,
			 error(String),
			 fn(Closure),
			 method(AnalyzedFuncExpr, StructInstance),
			 `struct`(StructType),
			 instance(StructInstance)

	public static func == (lhs: Value, rhs: Value) -> Bool {
		switch lhs {
		case let .int(int):
			guard case let .int(rhs) = rhs else {
				return false
			}

			return int == rhs
		case let .bool(bool):
			guard case let .bool(rhs) = rhs else {
				return false
			}

			return bool == rhs
		case .none:
			return false
		case .error:
			return false
		case let .fn(closure):
			guard case let .fn(rhs) = rhs else {
				return false
			}

			return closure.funcExpr.i == rhs.funcExpr.i
		case .method(_, _):
			return false
		case .struct(_), .instance(_):
			fatalError()
		}
	}

	public var isTruthy: Bool {
		switch self {
		case .int:
			true
		case .method(_):
			true
		case .struct(_), .instance(_):
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
		default:
			return .error("Cannot add \(other) to \(self)")
		}
	}
}
