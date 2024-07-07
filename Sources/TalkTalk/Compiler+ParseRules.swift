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
		guard let value = Int(lexeme) else {
			error("Could not parse number: \(parser.previous.lexeme(in: source))")
			return
		}

		emit(constant: .int(value))
	}

	func dot(_ canAssign: Bool) {
		parser.consume(.identifier, "Expected property name after '.'")

		let name = identifierConstant(parser.previous)

		if canAssign, parser.match(.equal) {
			expression()
			emit(opcode: .setProperty)
			emit(name)
		} else {
			emit(opcode: .getProperty)
			emit(name)
		}
	}

	func unary(_: Bool) {
		let kind = parser.previous.kind
		parse(precedence: .unary)

		// Emit the operator instruction
		if kind == .minus {
			emit(opcode: .negate)
		} else if kind == .bang {
			emit(opcode: .not)
		} else {
			error("Should be unreachable for nowz.")
		}
	}

	// MARK: Binary expressions

	func and(_: Bool) {
		let endJump = emit(jump: .jumpIfFalse)
		emit(opcode: .pop)
		parse(precedence: .and)
		patchJump(endJump)
	}

	func or(_: Bool) {
		let elseJump = emit(jump: .jumpIfFalse)
		let endJump = emit(jump: .jump)

		patchJump(elseJump)
		emit(opcode: .pop)

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
		case .plus: emit(opcode: .add)
		case .minus: emit(opcode: .subtract)
		case .star: emit(opcode: .multiply)
		case .slash: emit(opcode: .divide)
		case .equalEqual: emit(opcode: .equal)
		case .bangEqual: emit(opcode: .notEqual)
		case .less: emit(opcode: .less)
		case .lessEqual: emit(.greater, .not)
		case .greater: emit(opcode: .greater)
		case .greaterEqual: emit(.less, .not)
		default:
			() // Unreachable
		}
	}

	// MARK: Literals

	func literal(_: Bool) {
		switch parser.previous.kind {
		case .false: emit(opcode: .false)
		case .true: emit(opcode: .true)
		case .nil: emit(opcode: .nil)
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
		emit(constant: value)
	}

	func variable(_ canAssign: Bool) {
		namedVariable(parser.previous, canAssign)
	}
}
