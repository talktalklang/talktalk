//
//  Constraints.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/25/24.
//

class Constraints {
	var constraints: [any Constraint] = []

	func add(_ constraint: any Constraint) {
		constraints.append(constraint)
	}
}
