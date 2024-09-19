//
//  TypeVariable.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/25/24.
//

public struct TypeVariable: Equatable, Hashable, CustomStringConvertible, CustomDebugStringConvertible, Sendable {
	var id: VariableID
	var name: String?

	public static func new(_ named: String, _ id: Int? = nil) -> TypeVariable {
		TypeVariable(named, id ?? named.hashValue)
	}

	public static func extract(from type: InferenceType) -> TypeVariable? {
		guard case let .typeVar(typeVar) = type else {
			return nil
		}

		return typeVar
	}

	init(_ name: String?, _ id: VariableID) {
		self.id = id
		self.name = name
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
