//
//  Value.swift
//
//
//  Created by Pat Nakajima on 6/30/24.
//

// typealias Value = Double
enum Value: Equatable, Hashable {
	static func == (lhs: Value, rhs: Value) -> Bool {
		lhs.equals(rhs)
	}

	case error(String),
	     bool(Bool),
	     `nil`,
	     number(Double),
	     string(String),
	     closure(Closure),
	     function(Function),
	     native(String)

	func hash(into hasher: inout Swift.Hasher) {
		hasher.combine(hash)
	}

	func equals(_ other: Value) -> Bool {
		switch (self, other) {
		case let (.error(string), .error(other)):
			return string == other
		case let (.bool(bool), .bool(other)):
			return bool == other
		case (.nil, .nil):
			return true
		case let (.number(double), .number(other)):
			return double == other
		case let (.string(string), .string(other)):
			return string == other
		case let (.function(function), .function(other)):
			return function == other
		case let (.native(nativeFunction), .native(other)):
			return nativeFunction == other
		default:
			return false
		}
	}

	var hash: Int {
		switch self {
		case .error:
			return 0
		case let .bool(bool):
			return bool ? 1 : 0
		case .nil:
			fatalError("Attempted to use nil hash key")
		case let .number(double):
			return abs(double.hashValue)
		case let .string(heapValue):
			return Int(heapValue.hashValue)
		case let .function(function):
			return function.chunk.hashValue
		case let .closure(closure):
			return closure.function.chunk.hashValue
		case let .native(native):
			return native.hashValue
		}
	}

	func `as`<T>(_ type: T.Type) -> T {
		switch type {
		case is Bool.Type:
			if case let .bool(bool) = self {
				return bool as! T
			}
		case is String.Type:
			return description as! T
		case is Byte.Type:
			if case let .number(double) = self {
				return Byte(double) as! T
			}
		case is Function.Type:
			if case let .function(function) = self {
				return function as! T
			} else if case let .closure(closure) = self {
				return closure.function as! T
			}
		case is Closure.Type:
			if case let .closure(closure) = self {
				return closure as! T
			}
		default:
			()
		}

		fatalError("\(self) cast to \(T.self) not implemented.")
	}

	var description: String {
		switch self {
		case let .error(msg):
			return "Error: \(msg)"
		case let .bool(bool):
			return "\(bool)"
		case .nil:
			return "nil"
		case let .number(double):
			return "\(double)"
		case let .string(string):
			return string
		case let .function(function):
			return "<\(function.name)>"
		case let .closure(closure):
			return "<\(closure.function.name)>"
		case let .native(native):
			return "<native \(native)>"
		}
	}

	func not() -> Value {
		switch self {
		case let .bool(bool):
			.bool(!bool)
		default:
			.error("Cannot negate \(self)")
		}
	}

	static prefix func - (rhs: Value) -> Value {
		switch rhs {
		case let .number(double):
			.number(-double)
		default:
			.error("Cannot negate \(self)")
		}
	}

	static func + (lhs: Value, rhs: Value) -> Value {
		switch lhs {
		case let .number(lhs):
			guard case let .number(rhs) = rhs else {
				return .error("Cannot + \(rhs)")
			}

			return .number(lhs + rhs)
		case let .string(lhs):
			guard case let .string(rhs) = rhs else {
				return .error("Cannot + \(self)")
			}

			return Value.string(lhs + rhs)
		default:
			return .error("Cannot + \(lhs), \(rhs)")
		}
	}

	static func - (lhs: Value, rhs: Value) -> Value {
		guard case let .number(rhs) = rhs else {
			return .error("Cannot - \(rhs)")
		}

		return switch lhs {
		case let .number(lhs):
			.number(lhs - rhs)
		default:
			.error("Cannot - \(lhs) \(rhs)")
		}
	}

	static func * (lhs: Value, rhs: Value) -> Value {
		guard case let .number(rhs) = rhs else {
			return .error("Cannot * \(rhs)")
		}

		return switch lhs {
		case let .number(lhs):
			.number(lhs * rhs)
		default:
			.error("Cannot * \(lhs) \(rhs)")
		}
	}

	static func / (lhs: Value, rhs: Value) -> Value {
		guard case let .number(rhs) = rhs else {
			return .error("Cannot / \(rhs)")
		}

		return switch lhs {
		case let .number(lhs):
			.number(lhs / rhs)
		default:
			.error("Cannot / \(lhs) \(rhs)")
		}
	}

	static func < (lhs: Value, rhs: Value) -> Value {
		guard case let .number(rhs) = rhs else {
			return .error("Cannot < \(rhs)")
		}

		return switch lhs {
		case let .number(lhs):
			.bool(lhs < rhs)
		default:
			.error("Cannot < \(lhs) \(rhs)")
		}
	}

	static func > (lhs: Value, rhs: Value) -> Value {
		guard case let .number(rhs) = rhs else {
			return .error("Cannot > \(rhs)")
		}

		return switch lhs {
		case let .number(lhs):
			.bool(lhs > rhs)
		default:
			.error("Cannot > \(lhs) \(rhs)")
		}
	}
}

extension Value: ExpressibleByFloatLiteral {
	init(floatLiteral: Float) {
		self = .number(Double(floatLiteral))
	}
}
