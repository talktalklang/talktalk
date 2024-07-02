//
//  Value.swift
//
//
//  Created by Pat Nakajima on 6/30/24.
//

// typealias Value = Double

struct HeapValue<T>: Equatable {
	let pointer: UnsafePointer<T>
	let length: UInt32

	var pointee: T {
		pointer.pointee
	}
}

enum Value: Equatable {
	case error, bool(Bool), `nil`, number(Double), string(HeapValue<Character>)

	var description: String {
		switch self {
		case .error:
			return "Error"
		case .bool(let bool):
			return "\(bool)"
		case .nil:
			print("--------------- value mem size: \(MemoryLayout.size(ofValue: self))")
			return "nil"
		case .number(let double):
			return "\(double)"
		case .string(let heapValue):
			var string = ""

			for i in 0..<heapValue.length {
				string.append((heapValue.pointer + Int(i)).pointee)
			}

			print("--------------- value mem size: \(MemoryLayout.size(ofValue: self)), string: \(string)")

			return string
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
