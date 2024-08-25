//
//  Environment.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/25/24.
//

struct Environment {
	private var types: [String: Type] = [:]

	subscript(_ name: String) -> Type? {
		get {
			types[name]
		}

		set {
			types[name] = newValue
		}
	}

	mutating func extend(_ name: String, type: Type) {
		types[name] = type
	}
}
