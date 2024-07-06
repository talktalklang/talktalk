//
//  Compiler+ParseRules.swift
//  
//
//  Created by Pat Nakajima on 7/5/24.
//
extension Compiler {
	func grouping(_: Bool) {
		// Assume the initial "(" has been consumed
		expression()
		parser.consume(.rightParen, "Expected ')' after expression.")
	}

	func number(_: Bool) {
		let lexeme = parser.previous.lexeme(in: source).reduce(into: "") { $0.append($1) }
		guard let value = Double(lexeme) else {
			error("Could not parse number: \(parser.previous.lexeme(in: source))")
			return
		}

		emit(constant: .number(value), "number constant")
	}

	func unary(_: Bool) {
		let kind = parser.previous.kind
		parse(precedence: .unary)

		// Emit the operator instruction
		if kind == .minus {
			emit(opcode: .negate, "negate opcode")
		} else if kind == .bang {
			emit(opcode: .not, "not opcode")
		} else {
			error("Should be unreachable for nowz.")
		}
	}

	// MARK: Binary expressions

	func and(_: Bool) {
		let endJump = emit(jump: .jumpIfFalse)
		emit(opcode: .pop, "and pop")
		parse(precedence: .and)
		patchJump(endJump)
	}

	func or(_: Bool) {
		let elseJump = emit(jump: .jumpIfFalse)
		let endJump = emit(jump: .jump)

		patchJump(elseJump)
		emit(opcode: .pop, "or pop")

		parse(precedence: .or)
		patchJump(endJump)
	}

	func binary(_: Bool) {
		guard let kind = parser.previous?.kind else {
			error("No previous token for unary expr.")
			return
		}

		let rule = kind.rule
		parse(precedence: rule.precedence + 1)

		switch kind {
		case .plus: emit(opcode: .add, "plus opcode")
		case .minus: emit(opcode: .subtract, "minus opcode")
		case .star: emit(opcode: .multiply, "star opcode")
		case .slash: emit(opcode: .divide, "slash opcode")
		case .equalEqual: emit(opcode: .equal, "== opcode")
		case .bangEqual: emit(opcode: .notEqual, "!= opcode")
		case .less: emit(opcode: .less, "< opcode")
		case .lessEqual: emit(.greater, .not, "<= opcode")
		case .greater: emit(opcode: .greater, "> opcode")
		case .greaterEqual: emit(.less, .not, ">= opcode")
		default:
			() // Unreachable
		}
	}

	// MARK: Literals

	func literal(_: Bool) {
		switch parser.previous.kind {
		case .false: emit(opcode: .false, "false opcode")
		case .true: emit(opcode: .true, "true opcode")
		case .nil: emit(opcode: .nil, "nil opcode")
		default:
			() // Unreachable
		}
	}

	// TODO: add static string that we don't need to copy?
	func string(_: Bool) {
		// Get rid of start/end quotes
		let start = parser.previous.start + 1
		let length = parser.previous.length - 2
		let value = Value.string(String(source[start ..< start + length]))
		emit(constant: value, "string opcode")
	}

	func variable(_ canAssign: Bool) {
		namedVariable(parser.previous, canAssign)
	}
}
