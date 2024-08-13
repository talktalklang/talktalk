//
//  TypeRegistry.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/12/24.
//

public struct TypeID: Hashable, Codable {
	let id: Int
	let registry: TypeRegistry

	public func type() -> ValueType {
		registry.lookup(self)
	}

	public func update(_ type: ValueType) {
		registry.update(self, to: type)
	}
}

// The type registry maps unique identifiers to types. This way
// we don't need to embed type data into the types themselves.
//
// The main idea here is that types should be able to be updated any
// time new information becomes available. Also multiple things that
// are known to have the same type should get updated when you update one
// of them.
public class TypeRegistry: Equatable, Hashable, Codable {
	public static func ==(lhs: TypeRegistry, rhs: TypeRegistry) -> Bool {
		lhs.storage == rhs.storage
	}

	var storage: [TypeID: ValueType] = [:]

	public func lookup(_ typeID: TypeID) -> ValueType {
		if let type = storage[typeID] {
			return type
		}

		fatalError("no typeID found for \(typeID)")
	}

	func newType(_ initial: ValueType = .placeholder(0)) -> TypeID {
		let newType = TypeID(id: storage.count, registry: self)
		storage[newType] = initial
		return newType
	}

	func update(_ typeID: TypeID, to newValue: ValueType) {
		if storage[typeID] == nil {
			fatalError("no existing type found for typeID: \(typeID)")
		}

		storage[typeID] = newValue
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(storage)
	}
}
