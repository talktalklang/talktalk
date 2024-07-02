//
//  Compiler.swift
//  
//
//  Created by Pat Nakajima on 7/1/24.
//
public struct Compiler: ~Copyable {
	struct Error {
		var token: Token?
		var message: String
	}

	let source: String
	var parser: Parser
	var compilingChunk: Chunk
	var errors: [Error] = []

	public init(source: String) {
		self.source = source
		self.parser = Parser(lexer: Lexer(source: source))
		self.compilingChunk = Chunk()
	}

	public mutating func compile() {
		expression()
		parser.consume(.eof, "Expected end of expression")
		emit(.return)
	}

	mutating func expression() {
		parse(precedence: .assignment)
	}

	// Starting with parser.current, parse expressions at `precedence`
	// level or higher.
	mutating func parse(precedence: Parser.Precedence) {
		parser.advance()

		if !parser.errors.isEmpty {
			print("ERROR: \(parser.errors)")
		}

		let opKind = parser.previous.kind
		let rule = opKind.rule

		guard let prefix = rule.prefix else {
			error("Expected expression.")
			return
		}

		prefix(&self)

		while precedence < parser.current.kind.rule.precedence {
			parser.advance();

			if let infix = parser.previous.kind.rule.infix {
				infix(&self)
			}
		}
	}

	// MARK:  Prefix expressions

	mutating func grouping() {
		// Assume the initial "(" has been consumed
		expression()
		parser.consume(.rightParen, "Expected ')' after expression.")
	}

	mutating func number() {
		guard let previous = parser.previous, let value = Double(previous.lexeme(in: source)) else {
			error("Could not parse number.")
			return
		}

		emit(constant: .number(value))
	}

	mutating func unary() {
		let kind = parser.previous.kind
		parse(precedence: .unary)

		// Emit the operator instruction
		if kind == .minus {
			emit(.negate)
		} else if kind == .bang {
			emit(.not)
		} else {
			error("Should be unreachable for nowz.")
		}
	}

	// MARK: Binary expressions

	mutating func binary() {
		guard let kind = parser.previous?.kind else {
			error("No previous token for unary expr.")
			return
		}

		let rule = kind.rule
		parse(precedence: rule.precedence + 1)

		switch kind {
		case .plus: 	emit(.add)
		case .minus: 	emit(.subtract)
		case .star: 	emit(.multiply)
		case .slash: 	emit(.divide)
		case .equalEqual: emit(.equal)
		case .bangEqual: 	emit(.notEqual)
		default:
			() // Unreachable
		}
	}

	// MARK: Literals

	mutating func literal() {
		switch parser.previous.kind {
		case .false:	emit(.false)
		case .true:		emit(.true)
		case .nil:		emit(.nil)
		default:
			() // Unreachable
		}
	}

	// MARK: Emitters

	mutating func emit(constant value: consuming Value) {
		if compilingChunk.constants.count > UInt8.max {
			error("Too many constants in one chunk")
			return
		}

		compilingChunk.write(value: value, line: parser.previous?.line ?? -1)
	}

	mutating func emit(_ opcode: consuming Opcode) {
		compilingChunk.write(opcode.byte, line: parser.previous?.line ?? -1)
	}

	mutating func emit(_ byte: consuming Byte) {
		compilingChunk.write(byte, line: parser.previous?.line ?? -1)
	}

	mutating func emit(_ byte1: consuming Byte, emit byte2: consuming Byte) {
		emit(byte1)
		emit(byte2)
	}

	mutating func error(_ message: String) {
		errors.append(Error(token: nil, message: message))
	}
}
