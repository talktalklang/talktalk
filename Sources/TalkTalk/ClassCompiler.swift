//
//  ClassCompiler.swift
//
//
//  Created by Pat Nakajima on 7/7/24.
//
final class ClassCompiler {
	var parent: ClassCompiler?
	var hasSuperclass: Bool = false

	init(parent: ClassCompiler? = nil) {
		self.parent = parent
	}
}
