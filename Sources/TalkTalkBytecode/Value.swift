//
//  Value.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/2/24.
//

public class Instance: Equatable, Hashable, Codable, @unchecked Sendable {
	public static func ==(lhs: Instance, rhs: Instance) -> Bool {
		lhs.type == rhs.type && lhs.fields == rhs.fields
	}

	public let type: Struct
	public var fields: [Value?]

	public init(type: Struct, fields: [Value?]) {
		self.type = type
		self.fields = fields
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(type)
		hasher.combine(fields)
	}
}

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
	case `struct`(Struct)

	// The type of instance, the instance ID
	case instance(Instance)

	// The method slot, the type of instance
	case boundMethod(Instance, IntValue)

	case primitive(Primitive)

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

	public var structValue: Struct? {
		guard case let .struct(result) = self else {
			return nil
		}

		return result
	}

	public var instanceValue: Instance? {
		guard case let .instance(instance) = self else {
			return nil
		}

		return instance
	}

	public var boundMethodValue: (instance: Instance, slot: IntValue)? {
		guard case let .boundMethod(instance, slot) = self else {
			return nil
		}

		return (instance, slot)
	}

	public func disassemble(in chunk: StaticChunk) -> String {
		switch self {
		case .closure:
			"closure"
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
			"instance \(instanceValue!.type.name)"
		case .boundMethod:
			"bound method \(boundMethodValue!)"
		case .builtinStruct:
			"builtin struct"
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
		case (.pointer(_, _), .primitive(.pointer)):
			true
		case let (.instance(instance), .struct(type)):
			instance.type == type
		default:
			false
		}
	}
}
