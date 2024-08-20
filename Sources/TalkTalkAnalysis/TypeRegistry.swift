//
//  TypeRegistry.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/12/24.
//

import Foundation

// The typeID is a reference wrapper around a ValueType. This way
// we don't need to embed type data into the types themselves.
//
// The main idea here is that types should be able to be updated any
// time new information becomes available. Also multiple things that
// are known to have the same type should get updated when you update one
// of them.
public final class TypeID: Codable, Hashable, Equatable, CustomStringConvertible, @unchecked Sendable {
	public static func == (lhs: TypeID, rhs: TypeID) -> Bool {
		lhs.current == rhs.current
	}

	public var current: ValueType

	public init(_ initial: ValueType = .placeholder) {
		self.current = initial
	}

	public func type() -> ValueType {
		current
	}

	public func update(_ type: ValueType) {
		current = type
	}

	// Try to resolve generic types to concrete types based on instance bindings
	public func resolve(with instance: InstanceValueType) -> TypeID {
		guard case let .generic(instance.ofType, typeParam) = current else {
			return self
		}

		return instance.boundGenericTypes[typeParam] ?? self
	}

	public var description: String {
		switch current {
		case .none:
			"nope"
		case .int:
			"int"
		case .bool:
			"bool"
		case .byte:
			"byte"
		case .pointer:
			"pointer"
		case let .function(_, typeID, array, _):
			"func(\(array)) -> \(typeID.description)"
		case let .struct(string):
			string + ".Type"
		case let .generic(valueType, string):
			"\(valueType)<\(string)>"
		case let .instance(instanceValueType):
			switch instanceValueType.ofType {
			case let .struct(name): name
			default: instanceValueType.ofType.description
			}
		case let .member(valueType):
			"\(valueType) member"
		case let .error(string):
			string
		case .void:
			"void"
		case .placeholder:
			"<unknown>"
		case .any:
			"any"
		}
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(current)
	}

	public init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.current = try container.decode(ValueType.self, forKey: .current)
	}
}
