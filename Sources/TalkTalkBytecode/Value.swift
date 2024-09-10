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
	public var fields: [Symbol: Value]

	public init(type: Struct, fields: [Symbol: Value]) {
		self.type = type
		self.fields = fields
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(type)
		hasher.combine(fields)
	}
}

public enum Value: Equatable, Hashable, Codable, Sendable {
	// Just a value that goes on the stack
	case reserved

	case int(Int)

	case bool(Bool)

	// The index of some embedded data in the chunk
	case data(Int)

	// In case we wanna play with bytes?
	case byte(Byte)

	// Strings. It's fine.
	case string(String)

	// The block ID and the offset
	case pointer(Heap.Pointer)

	// The index of the closure
	case closure(Symbol)

	// The index of the builtin function
	case builtin(Symbol)

	// The index of the builtin struct
	case builtinStruct(Int)

	// The index of the module function in its lookup table
	case moduleFunction(Symbol)

	// The index of the struct in the module
	case `struct`(Struct)

	case `enum`(Enum)
	case enumCase(Enum, String)

	// The type of instance, the instance ID
	case instance(Instance)

	// The method slot, the type of instance
	case boundMethod(Instance, Symbol)

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

	public var intValue: Int? {
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

	public var dataValue: Int? {
		guard case let .data(data) = self else {
			return nil
		}

		return data
	}

	public var closureValue: Symbol? {
		guard case let .closure(result) = self else {
			return nil
		}

		return result
	}

	public var builtinValue: Symbol? {
		guard case let .builtin(result) = self else {
			return nil
		}

		return result
	}

	public var moduleFunctionValue: Symbol? {
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

	public var boundMethodValue: (instance: Instance, symbol: Symbol)? {
		guard case let .boundMethod(instance, symbol) = self else {
			return nil
		}

		return (instance, symbol)
	}

	public func disassemble(in module: Module) -> String {
		switch self {
		case .closure(let symbol):
			"closure(\(module.chunks[symbol]?.name ?? "<symbol not found: \(symbol)>"))"
		case .moduleFunction(let symbol):
			"moduleFunction(\(module.chunks[symbol]?.name ?? "<symbol not found: \(symbol)>"))"
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
		case .int(let int):
			".int(\(int))"
		case .bool(let bool):
			".bool(\(bool))"
		case .data(let data):
			".data(\(data))"
		case .closure:
			"closure"
		case .builtin:
			"builtin"
		case .moduleFunction(let id):
			"module function \(id)"
		case let .struct(type):
			"\(type.name).Type"
		case .instance(let instance):
			"instance \(instance.type.name)"
		case .boundMethod(let instance, let slot):
			"bound method \(instance), slot: \(slot)"
		case .builtinStruct:
			"builtin struct"
		case let .pointer(pointer):
			pointer.description
		case .primitive:
			"primitive"
		case .enum(let enumType):
			enumType.name
		case .enumCase(let enumType, let name):
			"\(enumType.name).\(name)"
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
		case let (.instance(instance), .struct(type)):
			instance.type == type
		default:
			false
		}
	}
}
