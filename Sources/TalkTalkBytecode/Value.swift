//
//  Value.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/2/24.
//

public class Instance: Equatable, Hashable, Codable, @unchecked Sendable {
	public static func == (lhs: Instance, rhs: Instance) -> Bool {
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

public class Binding: Equatable, Hashable, Codable, CustomStringConvertible {
	public static func == (lhs: Binding, rhs: Binding) -> Bool {
		lhs.value == rhs.value
	}

	public static func new() -> Binding {
		Binding(value: nil)
	}

	public var value: Value?

	public init(value: Value? = nil) {
		self.value = value
	}

	public var description: String {
		"\(value?.description ?? "<none>")"
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(value)
	}
}

public enum Value: Equatable, Hashable, Codable {
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

	// An enum type
	case `enum`(Enum)

	// An enum case (with no values). (Type, Name, Arity)
	case enumCase(EnumCase)

	// An enum case (bound to values) (Type, Name, Values)
	case boundEnumCase(BoundEnumCase)

	case binding(Binding)

	// The type of instance, the instance ID
	case instance(Instance)

	// The type of instance, the method slot
	case boundStructMethod(Instance, Symbol)

	// The enum type, the method slot
	case boundEnumMethod(EnumCase, Symbol)

	case primitive(Primitive)

	case none

	public static func == (lhs: Value, rhs: Value) -> Bool {
		switch (lhs, rhs) {
		case (_, .binding):
			true
		case (.binding, _):
			true
		case let (.int(lhs), .int(rhs)):
			lhs == rhs
		case let (.bool(lhs), .bool(rhs)):
			lhs == rhs
		case let (.data(lhs), .data(rhs)):
			lhs == rhs
		case let (.byte(lhs), .byte(rhs)):
			lhs == rhs
		case let (.string(lhs), .string(rhs)):
			lhs == rhs
		case let (.pointer(lhs), .pointer(rhs)):
			lhs == rhs
		case let (.closure(lhs), .closure(rhs)):
			lhs == rhs
		case let (.builtin(lhs), .builtin(rhs)):
			lhs == rhs
		case let (.builtinStruct(lhs), .builtinStruct(rhs)):
			lhs == rhs
		case let (.moduleFunction(lhs), .moduleFunction(rhs)):
			lhs == rhs
		case let (.struct(lhs), .struct(rhs)):
			lhs == rhs
		case let (.enum(lhs), .enum(rhs)):
			lhs == rhs
		case let (.enumCase(lhs), .enumCase(rhs)):
			lhs == rhs
		case let (.boundEnumCase(lhs), .boundEnumCase(rhs)):
			lhs == rhs
		case let (.instance(lhs), .instance(rhs)):
			lhs == rhs
		case let (.boundStructMethod(lhsA, lhsB), .boundStructMethod(rhsA, rhsB)):
			lhsA == rhsA && lhsB == rhsB
		case let (.primitive(lhs), .primitive(rhs)):
			lhs == rhs
		case (.none, .none):
			true
		default:
			false
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
		guard case let .boundStructMethod(instance, symbol) = self else {
			return nil
		}

		return (instance, symbol)
	}

	public func disassemble(in module: Module) -> String {
		switch self {
		case let .closure(symbol):
			"closure(\(module.chunks[symbol]?.name ?? "<symbol not found: \(symbol)>"))"
		case let .moduleFunction(symbol):
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
		case .byte:
			"byte"
		case let .int(int):
			".int(\(int))"
		case let .bool(bool):
			".bool(\(bool))"
		case let .data(data):
			".data(\(data))"
		case .closure:
			"closure"
		case .builtin:
			"builtin"
		case let .moduleFunction(id):
			"module function \(id)"
		case let .struct(type):
			"\(type.name).Type"
		case let .instance(instance):
			"instance \(instance.type.name)"
		case let .boundStructMethod(instance, slot):
			"bound method \(instance), slot: \(slot)"
		case let .boundEnumMethod(enumCase, slot):
			"bound method \(enumCase), slot: \(slot)"
		case .builtinStruct:
			"builtin struct"
		case let .pointer(pointer):
			pointer.description
		case .primitive:
			"primitive"
		case let .enum(enumType):
			enumType.name
		case let .enumCase(enumCase):
			"\(enumCase.type).\(enumCase.name)[arity: \(enumCase.arity)]"
		case let .boundEnumCase(enumCase):
			"\(enumCase.type).\(enumCase.name)(\(enumCase.values))"
		case let .binding(i):
			"binding#\(i)"
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
