//
//  Compiler+Functions.swift
//
//
//  Created by Pat Nakajima on 7/5/24.
//
extension Compiler {
	func function(kind: Function.Kind) {
		let compiler = Compiler(parent: self, kind: kind)
		compiler.currentClass = currentClass

		compiler.beginScope()
		compiler.function.name = String(parser.previous.lexeme(in: source))
		compiler.parser.consume(.leftParen, "Expected '(' after function name")

		if !compiler.parser.check(.rightParen) {
			repeat {
				compiler.function.arity += 1

				if compiler.function.arity > 255 {
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
		if kind == .initializer {
			compiler.emit(opcode: .getLocal)
			compiler.emit(0) // `self` is always 0 on the stack
			compiler.emit(opcode: .return)
		} else {
			compiler.emitReturn()
		}

		let constant = chunk.make(constant: .function(compiler.function))
		emit(opcode: .closure)
		emit(constant)
		for upvalue in compiler.upvalues {
			emit(upvalue.isLocal ? 1 : 0)
			emit(upvalue.index)
		}

		assert(compiler.upvalues.count == compiler.function.upvalueCount, "upvalue count != function upvalue count (\(compiler.upvalues.count) != \(compiler.function.upvalueCount))")
	}

	func call(_: Bool) {
		let terminator: Token.Kind = switch parser.previous.kind {
		case .leftParen: .rightParen
		case .leftBracket: .rightBracket
		default:
			{
				error("Invalid call", at: parser.previous)
				return .nil
			}()
		}

		let argCount = argumentList(terminator: terminator)
		emit(opcode: .call)
		emit(argCount)
	}

	func argumentList(terminator: Token.Kind = .rightParen) -> Byte {
		var count: Byte = 0
		if !parser.check(terminator) {
			repeat {
				expression()
				if count == 255 {
					error("Can't have more than 255 arguments, cmon", at: parser.previous)
				}
				count += 1
			} while parser.match(.comma)
		}

		parser.consume(terminator, "Expected '\(terminator)' after arguments")
		return count
	}
}
