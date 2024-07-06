//
//  Upvalue.swift
//
//
//  Created by Pat Nakajima on 7/4/24.
//
struct Upvalue {
	let isLocal: Bool
	let index: Byte

	init(isLocal: Bool, index: Byte) {
		self.isLocal = isLocal
		self.index = index
	}
}
