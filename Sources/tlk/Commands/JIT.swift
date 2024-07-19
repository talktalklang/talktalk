//
//  JIT.swift
//
//
//  Created by Pat Nakajima on 7/11/24.
//
import ArgumentParser
import Foundation
import TalkTalkCompiler

struct JIT: AsyncParsableCommand {
	@Argument(help: "The input to run. Use `-` for stdin.")
	var input: String

	@Flag(help: "Run module passes")
	var optimize: Bool = false

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

		let compiler = Compiler(filename: filename, source: source)
		let module = try compiler.compile(optimize: optimize)

		if emitIR {
			module.dump()
		} else {
			print(LLVM.JIT().execute(module: module)!)
		}
	}
}
