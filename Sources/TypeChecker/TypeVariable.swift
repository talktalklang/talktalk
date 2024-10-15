//
//  TypeVariable.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/25/24.
//

public typealias VariableID = Int

public struct TypeVariable: Equatable, Hashable, CustomStringConvertible, CustomDebugStringConvertible, Sendable {
	var id: VariableID
	var name: String?

	// If a type variable is generic then it is an error to try to unify it directly
	var isGeneric: Bool = false

	public static func new(_ named: String, _ id: Int? = nil, isGeneric: Bool = false) -> TypeVariable {
		TypeVariable(named, id ?? named.hashValue, isGeneric)
	}

	public static func extract(from type: InferenceType) -> TypeVariable? {
		guard case let .typeVar(typeVar) = type else {
			return nil
		}

		return typeVar
	}

	init(_ name: String?, _ id: VariableID, _ isGeneric: Bool = false) {
		self.id = id
		self.name = name
		self.isGeneric = isGeneric
	}

	public var debugDescription: String {
		if let name {
			"T(\(id) \(name))"
		} else {
			"T(\(id))"
		}
	}

	public var description: String {
		if let name {
			name
		} else {
			"T(\(id))"
		}
	}
}
