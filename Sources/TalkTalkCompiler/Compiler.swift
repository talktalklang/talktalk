//
//  Compiler.swift
//
//
//  Created by Pat Nakajima on 7/15/24.
//
import SwiftyLLVM

public struct Compiler {
	let source: String

	public init(source: String) {
		self.source = source
	}

	public func compile() {
		var module = SwiftyLLVM.Module("TalkTalk")
		print(module.type(named: "Person"))
		print(module)
	}
}
