//
//  Value.swift
//
//
//  Created by Pat Nakajima on 6/30/24.
//

// typealias Value = Double

struct HeapValue<T>: Equatable {
	let pointer: UnsafePointer<T>
	var pointee: T {
		pointer.pointee
	}
}

enum Value: Equatable {
	case error, bool(Bool), `nil`, number(Double), string(HeapValue<String>)

	var description: String {
		switch self {
		case .error:
			"Error"
		case .bool(let bool):
			"\(bool)"
		case .nil:
			"nil"
		case .number(let double):
			"\(double)"
		case .string(let heapValue):
			heapValue.pointee.debugDescription
		}
	}

	func not() -> Value {
		switch self {
		case .bool(let bool):
			.bool(!bool)
		default:
			.error
		}
	}

	static prefix func -(rhs: Value) -> Value {
		switch rhs {
		case .number(let double):
			.number(-double)
		default:
			.error
		}
	}

	static func +(lhs: Value, rhs: Value) -> Value {
		guard case .number(let rhs) = rhs else {
			return .error
		}

		return switch lhs {
		case .number(let lhs):
			.number(lhs + rhs)
		default:
			.error
		}
	}

	static func -(lhs: Value, rhs: Value) -> Value {
		guard case .number(let rhs) = rhs else {
			return .error
		}

		return switch lhs {
		case .number(let lhs):
			.number(lhs - rhs)
		default:
			.error
		}
	}

	static func *(lhs: Value, rhs: Value) -> Value {
		guard case .number(let rhs) = rhs else {
			return .error
		}

		return switch lhs {
		case .number(let lhs):
			.number(lhs * rhs)
		default:
			.error
		}
	}

	static func /(lhs: Value, rhs: Value) -> Value {
		guard case .number(let rhs) = rhs else {
			return .error
		}

		return switch lhs {
		case .number(let lhs):
			.number(lhs / rhs)
		default:
			.error
		}
	}
}

extension Value: ExpressibleByFloatLiteral {
	init(floatLiteral: Float) {
		self = .number(Double(floatLiteral))
	}
}
