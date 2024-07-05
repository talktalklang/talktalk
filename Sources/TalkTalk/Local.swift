//
//  Local.swift
//  
//
//  Created by Pat Nakajima on 7/5/24.
//
class Local {
	let name: Token
	var depth: Int
	var isInitialized = false

	init(name: Token, depth: Int, isInitialized: Bool = false) {
		self.name = name
		self.depth = depth
		self.isInitialized = isInitialized
	}
}
