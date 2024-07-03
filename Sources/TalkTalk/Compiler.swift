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

	let source: [Character]
	var parser: Parser
	var compilingChunk: Chunk
	var errors: [Error] = []

	#if DEBUG
	var parserRepeats: [Int: Int] = [:]

	mutating func checkForInfiniteLoop() {
		parserRepeats[parser.current.start, default: 0] += 1

		if parserRepeats[parser.current.start]! > 100 {
			fatalError("Probably an infinite loop goin pat.")
		}
	}
	#endif

	public init(source: String) {
		self.source = Array(source)
		self.parser = Parser(lexer: Lexer(source: source))
		self.compilingChunk = Chunk()
	}

	public mutating func compile() {
		while parser.current.kind != .eof {
			declaration()

			#if DEBUG
			checkForInfiniteLoop()
			#endif
		}

		emit(.return)
	}

	mutating func declaration() {
		if parser.match(.var) {
			varDeclaration()
		} else {
			statement()
		}
	}

	mutating func varDeclaration() {
		let global = parseVariable("Expected variable name")
		
		defer {
			emit(.defineGlobal)
			emit(global)
		}

		if parser.match(.equal) {
			expression()
		} else {
			emit(.nil)
		}

		parser.consume(.semicolon, "Expected ';' after variable declaration")
	}

	// MARK: Statements

	mutating func statement() {
		if parser.match(.print) {
			printStatement()
		} else {
			expressionStatement()
		}
	}

	mutating func printStatement() {
		expression()
		parser.consume(.semicolon, "Expected ';' after value.")
		emit(.print)
	}

	mutating func expressionStatement() {
		expression()
		parser.consume(.semicolon, "Expected ';' after expression")
		emit(.pop)
	}

	mutating func expression() {
		parse(precedence: .assignment)
	}

	mutating func parseVariable(_ message: String) -> Byte {
		parser.consume(.identifier, message)
		return identifierConstant(parser.previous)
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
		let lexeme = parser.previous.lexeme(in: source).reduce(into: "") { $0.append($1) }
		guard let value = Double(lexeme) else {
			error("Could not parse number: \(parser.previous.lexeme(in: source))")
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

	// TODO: add static string that we don't need to copy?
	mutating func string() {
		// Get rid of start/end quotes
		let start = parser.previous.start + 1
		let length = parser.previous.length - 2

		// _We_ want to be the ones to allocate and copy the string
		// from the source file to the heap... for learning.
		let pointer = UnsafeMutablePointer<Character>.allocate(capacity: length)

		let source = ContiguousArray(parser.lexer.source)

		// Calculate the hash value while we're copying characters anyway
		var hasher = Hasher() //

		// This might not be right?
		source[start..<(start + length)].withUnsafeBufferPointer {
			for i in 0..<length {
				pointer[i] = $0[i]
				hasher.combine($0[i])
			}
		}

		// Trying to keep C semantics in swift is goin' great, pat.
		let heapValue = HeapValue<Character>(
			pointer: pointer,
			length: length,
			hashValue: hasher.value
		)

		let value = Value.string(heapValue)
		emit(constant: value)
	}

	mutating func variable() {
		namedVariable(parser.previous)
	}

	// MARK: Helpers

	mutating func namedVariable(_ token: Token) {
		let arg = identifierConstant(token)
		emit(.getGlobal)
		emit(arg)
	}

	mutating func identifierConstant(_ token: Token) -> Byte {
		let value = Value.string(token.lexeme(in: source))
		return compilingChunk.write(constant: value)
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

	mutating func emit(_ byte1: consuming Byte, _ byte2: consuming Byte) {
		emit(byte1)
		emit(byte2)
	}

	mutating func error(_ message: String) {
		print("Compiler message: \(message)")
		errors.append(Error(token: nil, message: message))
	}
}
