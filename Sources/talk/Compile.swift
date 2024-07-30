//
//  Compile.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/29/24.
//
import ArgumentParser
import Foundation
import TalkTalkCompiler
import LLVM
import C_LLVM

struct Compile: TalkTalkCommand {
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

		module.write(to: "out.bc")

		// Write the module to a file
	}
}
