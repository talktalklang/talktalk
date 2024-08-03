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
import TalkTalkLLVMExperimental
import LLVM

struct JITExperimental: TalkTalkCommand {
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

		let module = try Compiler(source).compile()
		_ = LLVM.JIT().execute(module: module)
	}
}