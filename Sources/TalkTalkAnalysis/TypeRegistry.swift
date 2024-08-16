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
final public class TypeID: Codable, Hashable, Equatable, CustomStringConvertible {
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
		case .function(_, let typeID, let array, _):
			"func(\(array)) -> \(typeID.description)"
		case .struct(let string):
			string + ".Type"
		case .generic(let valueType, let string):
			"\(valueType)<\(string)>"
		case .instance(let instanceValueType):
			switch instanceValueType.ofType {
			case let .struct(name): name
			default: instanceValueType.ofType.description
			}
		case .member(let valueType):
			"\(valueType) member"
		case .error(let string):
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

//
//public actor TypeRegistry: Equatable, Hashable, Sendable {
//	nonisolated let uuid = UUID()
//
//	public static func ==(lhs: TypeRegistry, rhs: TypeRegistry) -> Bool {
//		lhs.uuid == rhs.uuid
//	}
//
//	var storage: [Int: ValueType] = [:]
//
//	public func lookup(_ typeID: TypeID) -> ValueType {
//		if let type = storage[typeID.id] {
//			return type
//		}
//
//		fatalError("no typeID found for \(typeID)")
//	}
//
//	func newType(_ initial: ValueType = .placeholder) -> TypeID {
//		let newType = TypeID(
//			id: storage.count,
//			registry: self
//		)
//		storage[newType.id] = initial
//		return newType
//	}
//
//	func update(_ typeID: TypeID, to newValue: ValueType) {
//		if storage[typeID.id] == nil {
//			fatalError("no existing type found for typeID: \(typeID)")
//		}
//
//		storage[typeID.id] = newValue
//	}
//
//	nonisolated public func hash(into hasher: inout Hasher) {
//		hasher.combine(uuid)
//	}
//}
