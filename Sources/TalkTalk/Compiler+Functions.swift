//
//  Compiler+Functions.swift
//  
//
//  Created by Pat Nakajima on 7/5/24.
//
extension Compiler {
	func function(_: Function.Kind) {
		let compiler = Compiler(parent: self)

		compiler.beginScope()
		compiler.currentFunction.name = String(parser.previous.lexeme(in: source))
		compiler.parser.consume(.leftParen, "Expected '(' after function name")

		if !compiler.parser.check(.rightParen) {
			repeat {
				compiler.currentFunction.arity += 1

				if compiler.currentFunction.arity > 255 {
					compiler.parser.error(at: parser.current, "Can't have more than 255 params, cmon.")
				}

				let constant = compiler.parseVariable("Expected parameter name")
				compiler.defineVariable(global: constant)
			} while compiler.parser.match(.comma)
		}

		compiler.parser.consume(.rightParen, "Expected ')' after function parameters")
		compiler.parser.consume(.leftBrace, "Expected '{' before function body")
		compiler.block()

		// Always generate a return at the end of a function in case there's
		// not an explicit one. if there's an explicit one then this one will never
		// get executed
		compiler.emitReturn()

		let constant = compilingChunk.make(constant: .function(compiler.currentFunction))
		emit(opcode: .closure)
		emit(constant)
		for upvalue in compiler.upvalues {
			emit(upvalue.isLocal ? 1 : 0)
			emit(upvalue.index)
		}

		assert(compiler.upvalues.count == compiler.currentFunction.upvalueCount, "upvalue count != function upvalue count (\(compiler.upvalues.count) != \(compiler.currentFunction.upvalueCount))")
	}

	func call(_: Bool) {
		let argCount = argumentList()
		emit(opcode: .call)
		emit(argCount)
	}

	func argumentList() -> Byte {
		var count: Byte = 0
		if !parser.check(.rightParen) {
			repeat {
				expression()
				if count == 255 {
					error("Can't have more than 255 arguments, cmon", at: parser.previous)
				}
				count += 1
			} while parser.match(.comma)
		}

		parser.consume(.rightParen, "Expected ')' after arguments")
		return count
	}
}
