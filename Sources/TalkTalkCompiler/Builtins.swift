//
//  Builtins.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/29/24.
//

import LLVM
import C_LLVM

public struct Builtins {
	static let list: [any LLVM.BuiltinFunction.Type] = [
		Builtins.Printf.self
	]
}
