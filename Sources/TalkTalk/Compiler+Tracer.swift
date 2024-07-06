//
//  Compiler+.swift
//  
//
//  Created by Pat Nakajima on 7/5/24.
//
class CompilerTracer {
	enum State {
		case none, constant, closure
	}

	var state: State = .none
	let compiler: Compiler

	init(compiler: Compiler) {
		self.compiler = compiler
	}

	func state(_ state: State) {
		self.state = state
	}

	func trace(_ instruction: Byte, message: String) {
		let parts = [
			"\(compiler.parser.lexer.line):",
			String(compiler.parser.previous.lexeme(in: compiler.source)),
			"\((message.contains("opcode") ? Opcode(rawValue: instruction)?.description : instruction.description)!)",
			"\(message)"
		]

//		print(parts.joined(separator: "\t\t"))
	}
}
