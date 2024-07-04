//
//  Value.swift
//
//
//  Created by Pat Nakajima on 6/30/24.
//

// typealias Value = Double

struct HeapValue<T: Equatable>: Equatable {
	static func == (lhs: HeapValue<T>, rhs: HeapValue<T>) -> Bool {
		lhs.hashValue == rhs.hashValue && lhs.length == rhs.length && lhs.pointee == rhs.pointee
	}

	let pointer: UnsafePointer<T>
	let length: Int
	let hashValue: Int

	var pointee: T {
		pointer.pointee
	}
}

enum Value: Equatable, Hashable {
	case error(String), bool(Bool), `nil`, number(Double), string(HeapValue<Character>)

	func hash(into hasher: inout Hasher) {
		hasher.combine(hashValue)
	}

	var hashValue: Int {
		switch self {
		case .error:
			return 0
		case let .bool(bool):
			return bool ? 1 : 0
		case .nil:
			fatalError("Attempted to use nil hash key")
		case var .number(double):
			return abs(double.hashValue)
		case let .string(heapValue):
			return Int(heapValue.hashValue)
		}
	}

	static func string(lhs: HeapValue<Character>, rhs: HeapValue<Character>) -> Value {
		let pointer = UnsafeMutablePointer<Character>.allocate(capacity: lhs.length + rhs.length)
		pointer.initialize(repeating: "0", count: lhs.length + rhs.length)
		var hasher = Hasher()

		for i in 0 ..< lhs.length {
			pointer[i] = lhs.pointer[i]
			hasher.combine(lhs.pointer[i])
		}

		for i in 0 ..< rhs.length {
			pointer[lhs.length + i] = rhs.pointer[i]
			hasher.combine(rhs.pointer[i])
		}

		let heapValue = HeapValue<Character>(
			pointer: pointer,
			length: lhs.length + rhs.length,
			hashValue: hasher.value
		)

		return .string(heapValue)
	}

	static func string(_ string: String) -> Value {
		Value.string(ContiguousArray(string))
	}

	static func string(_ source: ContiguousArray<Character>) -> Value {
		let pointer = UnsafeMutablePointer<Character>.allocate(capacity: source.count)
		pointer.initialize(repeating: "0", count: source.count)

		// This might not be right?
		var hasher = Hasher()
		source.withUnsafeBufferPointer {
			for i in 0 ..< source.count {
				pointer[i] = $0[i]
				hasher.combine($0[i])
			}
		}

		// Trying to keep C semantics in swift is goin' great, pat.
		let heapValue = HeapValue<Character>(
			pointer: pointer,
			length: source.count,
			hashValue: hasher.value
		)

		return .string(heapValue)
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
		case let .string(heapValue):
			var string = ""

			for i in 0 ..< heapValue.length {
				string.append((heapValue.pointer + Int(i)).pointee)
			}

			return string
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

			return Value.string(lhs: lhs, rhs: rhs)
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
