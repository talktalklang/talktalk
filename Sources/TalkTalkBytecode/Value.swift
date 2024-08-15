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

	case byte(Byte)

	// The block ID and the offset
	case pointer(IntValue, IntValue)

	// The index of the closure
	case closure(IntValue)

	// The index of the builtin function
	case builtin(IntValue)

	// The index of the builtin struct
	case builtinStruct(IntValue)

	// The index of the module function in its lookup table
	case moduleFunction(IntValue)

	// The index of the struct in the module
	case `struct`(IntValue)

	// The type of instance, the instance ID
	case instance(IntValue, IntValue)

	// The method slot, the type of instance
	case boundMethod(IntValue, IntValue)

	case none

	public var isCallable: Bool {
		switch self {
		case .closure: true
		case .builtin: true
		case .builtinStruct: true
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

	public var builtinValue: IntValue? {
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

	public var structValue: IntValue? {
		guard case let .struct(result) = self else {
			return nil
		}

		return result
	}

	public var instanceValue: (IntValue, IntValue)? {
		guard case let .instance(type, instance) = self else {
			return nil
		}

		return (type, instance)
	}

	public var boundMethodValue: (slot: IntValue, instanceID: IntValue)? {
		guard case let .boundMethod(methodSlot, instance) = self else {
			return nil
		}

		return (methodSlot, instance)
	}

	public func disassemble(in chunk: Chunk) -> String {
		switch self {
		case .closure:
			"closure(\(chunk.getChunk(at: Int(closureValue!)).name))"
		default:
			description
		}
	}
}

extension Value: CustomStringConvertible {
	public var description: String {
		switch self {
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
		case .builtinStruct:
			"builtin struct"
		case .pointer:
			"pointer"
		case .none:
			"none"
		}
	}
}
