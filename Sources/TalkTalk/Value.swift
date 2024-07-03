//
//  Value.swift
//
//
//  Created by Pat Nakajima on 6/30/24.
//

// typealias Value = Double

struct HeapValue<T: Equatable>: Equatable {
	static func ==(lhs: HeapValue<T>, rhs: HeapValue<T>) -> Bool {
		lhs.hashValue == rhs.hashValue && lhs.length == rhs.length && lhs.pointee == rhs.pointee
	}

	let pointer: UnsafePointer<T>
	let length: Int
	let hashValue: Int

	var pointee: T {
		pointer.pointee
	}
}

enum Value: Equatable {
	case error, bool(Bool), `nil`, number(Double), string(HeapValue<Character>)

	var hashValue: Int {
		switch self {
		case .error:
			return 0
		case .bool(let bool):
			return bool ? 1 : 0
		case .nil:
			fatalError("Attempted to use nil hash key")
		case .number(var double):
			var hasher = Hasher()
			withUnsafeBytes(of: &double) {
				for i in $0 { hasher.combine(Int(i)) }
			}
			return abs(hasher.value)
		case .string(let heapValue):
			return Int(heapValue.hashValue)
		}
	}

	static func string(_ string: String) -> Value {
		let source = ContiguousArray(string)
		let pointer = UnsafeMutablePointer<Character>.allocate(capacity: string.count)

		// This might not be right?
		var hasher = Hasher()
		source.withUnsafeBufferPointer {
			for i in 0..<source.count {
				pointer[i] = $0[i]
				hasher.combine($0[i])
			}
		}

		// Trying to keep C semantics in swift is goin' great, pat.
		let heapValue = HeapValue<Character>(
			pointer: pointer,
			length: string.count,
			hashValue: hasher.value
		)

		print("Hash value for: \(string), \(hasher.value)")

		return .string(heapValue)
	}

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
