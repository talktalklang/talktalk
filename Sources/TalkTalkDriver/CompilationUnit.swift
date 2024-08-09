//
//  CompilationUnit.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/8/24.
//

import Foundation

struct CompilationUnit {
	let name: String
	let files: [URL]

	init(name: String, files: [URL]) {
		self.name = name
		self.files = files
	}
}
