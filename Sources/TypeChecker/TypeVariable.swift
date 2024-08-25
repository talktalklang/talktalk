//
//  Variable.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/25/24.
//

struct TypeVariable: Equatable {
	var id: VariableID
	var name: String

	init(_ name: String, _ id: VariableID) {
		self.id = id
		self.name = name
	}
}
