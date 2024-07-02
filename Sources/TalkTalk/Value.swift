//
//  Value.swift
//
//
//  Created by Pat Nakajima on 6/30/24.
//

// typealias Value = Double

enum Value {
	case error(String), bool(Bool), `nil`, number(Double)

	static prefix func -(rhs: Value) -> Value {
		switch rhs {
		case .bool(_):
			.error("Cannot - a bool")
		case .nil:
			.error("Cannot - nil")
		case .number(let double):
			.number(-double)
		case .error:
			.error("Cannot - error")
		}
	}

	static func +(lhs: Value, rhs: Value) -> Value {
		guard case let .number(rhs) = rhs else {
			return .error("Cannot + \(rhs)")
		}

		return switch lhs {
		case .number(let lhs):
			.number(lhs + rhs)
		default:
			.error("Cannot - \(lhs)")
		}
	}

	static func -(lhs: Value, rhs: Value) -> Value {
		guard case let .number(rhs) = rhs else {
			return .error("Cannot + \(rhs)")
		}

		return switch lhs {
		case .number(let lhs):
				.number(lhs / rhs)
		default:
			.error("Cannot - \(lhs)")
		}
	}

	static func *(lhs: Value, rhs: Value) -> Value {
		guard case let .number(rhs) = rhs else {
			return .error("Cannot + \(rhs)")
		}

		return switch lhs {
		case .number(let lhs):
				.number(lhs * rhs)
		default:
			.error("Cannot - \(lhs)")
		}
	}

	static func /(lhs: Value, rhs: Value) -> Value {
		guard case let .number(rhs) = rhs else {
			return .error("Cannot + \(rhs)")
		}

		return switch lhs {
		case .number(let lhs):
			.number(lhs / rhs)
		default:
			.error("Cannot - \(lhs)")
		}
	}
}

extension Value: ExpressibleByFloatLiteral {
	init(floatLiteral: Float) {
		self = .number(Double(floatLiteral))
	}
}
