//
//  JIT.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/29/24.
//

//
//  AST.swift
//
//
//  Created by Pat Nakajima on 7/11/24.
//
import ArgumentParser
import Foundation
import TalkTalkCompiler
import LLVM

struct JIT: TalkTalkCommand {
	@Argument(help: "The input to run.")
	var input: String

	func run() async throws {
		let source = switch try get(input: input) {
		case .path(let string):
			string
		case .stdin:
			fatalError("not yet")
		case .string(let string):
			string
		}

		let module = Compiler(source).compile()
		_ = LLVM.JIT().execute(module: module)
	}
}
