//
//  Local.swift
//
//
//  Created by Pat Nakajima on 7/5/24.
//
struct Local {
	let name: Token
	var depth: Int
	var isCaptured = false

	init(name: Token, depth: Int) {
		self.name = name
		self.depth = depth
	}

	var isInitialized: Bool {
		depth != -1
	}
}
