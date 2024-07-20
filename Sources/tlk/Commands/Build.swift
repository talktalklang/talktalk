//
//  Build.swift
//
//
//  Created by Pat Nakajima on 7/11/24.
//
import ArgumentParser
import Foundation
import TalkTalkCompiler

struct Build: AsyncParsableCommand {
	@Argument(help: "The input to run. Use `-` for stdin.")
	var input: String

	@Flag(name: .customLong("emit-ir"), help: "Just emit the LLVM IR")
	var emitIR: Bool = false

	func run() async throws {
		let filename: String
		let source: String

		if FileManager.default.fileExists(atPath: input) {
			filename = input
			source = try String(contentsOfFile: input)
		} else {
			filename = "<stdin>"
			source = input
		}

		let compiler = Compiler(file: .init(path: filename, source: source))
		let module = try compiler.compile()

		if emitIR {
			module.dump()
		} else {
			print(LLVM.JIT().execute(module: module)!)
		}
	}
}
