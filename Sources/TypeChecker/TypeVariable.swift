//
//  Variable.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/25/24.
//

public struct TypeVariable: Equatable, Hashable, CustomStringConvertible, Sendable {
	var id: VariableID
	var name: String?

	public static func new(_ named: String) -> TypeVariable {
		TypeVariable(named, named.hashValue)
	}

	init(_ name: String?, _ id: VariableID) {
		self.id = id
		self.name = name
	}

	public var description: String {
		if let name {
			"T(\(id), \(name.debugDescription))"
		} else {
			"T(\(id))"
		}
	}
}
