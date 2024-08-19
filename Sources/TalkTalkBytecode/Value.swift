//
//  Value.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/2/24.
//

public enum Value: Equatable, Hashable, Codable, Sendable {
	public typealias IntValue = Int32

	// Just a value that goes on the stack
	case reserved

	case int(IntValue)

	case bool(Bool)

	// The index of some embedded data in the chunk
	case data(IntValue)

	// In case we wanna play with bytes?
	case byte(Byte)

	// Strings. It's fine.
	case string(String)

	// The block ID and the offset
	case pointer(Heap.Pointer)

	// The index of the closure
	case closure(IntValue)

	// The index of the builtin function
	case builtin(Byte)

	// The index of the module function in its lookup table
	case moduleFunction(IntValue)

	// The struct object
	case `struct`(Struct)

	// The instance
	case instance(Instance)

	// The instance, the method slot
	case boundMethod(Instance, IntValue)

	case primitive(Primitive)

	case none

	public var isCallable: Bool {
		switch self {
		case .closure: true
		case .builtin: true
		case .moduleFunction: true
		case .struct: true
		case .boundMethod: true
		default: false
		}
	}

	public var intValue: IntValue? {
		guard case let .int(int) = self else {
			return nil
		}

		return int
	}

	public var boolValue: Bool? {
		guard case let .bool(bool) = self else {
			return nil
		}

		return bool
	}

	public var dataValue: IntValue? {
		guard case let .data(data) = self else {
			return nil
		}

		return data
	}

	public var closureValue: IntValue? {
		guard case let .closure(result) = self else {
			return nil
		}

		return result
	}

	public var builtinValue: Byte? {
		guard case let .builtin(result) = self else {
			return nil
		}

		return result
	}

	public var moduleFunctionValue: IntValue? {
		guard case let .moduleFunction(result) = self else {
			return nil
		}

		return result
	}

	public var structValue: Struct? {
		guard case let .struct(result) = self else {
			return nil
		}

		return result
	}

	public var instanceValue: (Instance)? {
		guard case let .instance(instance) = self else {
			return nil
		}

		return (instance)
	}

	public var boundMethodValue: (instance: Instance, methodSlot: IntValue)? {
		guard case let .boundMethod(instance, methodSlot) = self else {
			return nil
		}

		return (instance, methodSlot)
	}

	public func disassemble(in chunk: Chunk) -> String {
		switch self {
		case .closure:
			"closure(\(chunk.maybeGetChunk(at: Int(closureValue!))?.name as Any))"
		default:
			description
		}
	}
}

extension Value: CustomStringConvertible {
	public var description: String {
		switch self {
		case let .string(string):
			string.debugDescription
		case .reserved:
			"reserved"
		case .byte:
			"byte"
		case .int:
			".int(\(intValue!))"
		case .bool:
			".bool(\(boolValue!))"
		case .data:
			".data(\(dataValue!))"
		case .closure:
			"closure"
		case .builtin:
			"builtin"
		case .moduleFunction:
			"module function"
		case .struct:
			"struct"
		case .instance:
			"instance \(instanceValue!)"
		case .boundMethod:
			"bound method \(boundMethodValue!)"
		case .pointer:
			"pointer"
		case .primitive:
			"primitive"
		case .none:
			"none"
		}
	}

	public func `is`(_ value: Value) -> Bool {
		switch (self, value) {
		case (.int(_), .primitive(.int)):
			true
		case (.bool(_), .primitive(.bool)):
			true
		case (.byte(_), .primitive(.byte)):
			true
		case (.string(_), .primitive(.string)):
			true
		case (.pointer(_), .primitive(.pointer)):
			true
		case let (.instance(instance), .struct(structType)):
			instance.type == structType
		default:
			false
		}
	}
}
