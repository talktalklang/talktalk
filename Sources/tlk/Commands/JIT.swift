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

	@Flag(name: .customLong("emit-ir"), help: "Just emit the LLVM IR")
	var emitIR: Bool = false

	func run() async throws {
		let source = if FileManager.default.fileExists(atPath: input) {
			try String(contentsOfFile: input)
		} else if input == "-" {
			{
				var source = ""
				while let line = readLine() {
					source += line
				}
				return source
			}()
		} else {
			input
		}

		let compiler = Compiler(source: source)
		let module = try compiler.compile()

		if emitIR {
			module.dump()
		} else {
			print(LLVM.JIT().execute(module: module)!)
		}
	}
}
