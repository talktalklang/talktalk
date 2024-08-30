//
//  Variable.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/25/24.
//

struct TypeVariable: Equatable, Hashable, CustomStringConvertible {
	var id: VariableID
	var name: String?

	init(_ name: String?, _ id: VariableID) {
		self.id = id
		self.name = name
	}

	var description: String {
		if let name {
			"T(\(id), \(name.debugDescription))"
		} else {
			"T(\(id))"
		}
	}
}
