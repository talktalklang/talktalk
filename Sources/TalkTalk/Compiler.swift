//
//  Compiler.swift
//
//
//  Created by Pat Nakajima on 7/1/24.
//
public struct Compiler: ~Copyable {
	enum Errors: Swift.Error {
		case errors([Error])
	}

	struct Error {
		var token: Token?
		var message: String

		var description: String {
			if let token {
				"Compiler Error: \(message) at \(token)"
			} else {
				"Compiler Error: \(message)"
			}
		}
	}

	var parser: Parser
	var compilingChunk: Chunk
	var errors: [Error] = []

	// MARK: Local variable management

	struct Local {
		let name: Token
		var depth: Int
		var isInitialized = false
	}

	var locals = ContiguousArray<Local?>(repeating: nil, count: 256)
	var localCount = 0
	var scopeDepth = 0

	// MARK: Debuggy

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
		self.parser = Parser(lexer: Lexer(source: source))
		self.compilingChunk = Chunk()
	}

	var source: ContiguousArray<Character> {
		parser.lexer.source
	}

	public mutating func compile() throws {
		while parser.current.kind != .eof {
			declaration()

			#if DEBUG
				checkForInfiniteLoop()
			#endif
		}

		if errors.isEmpty {
			emit(.return)
			return
		}

		throw Errors.errors(errors)
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
			defineVariable(global: global)
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
		} else if parser.match(.if) {
			ifStatement()
		} else if parser.match(.while) {
			whileStatement()
		} else if parser.match(.leftBrace) {
			withScope { $0.block() }
		} else {
			expressionStatement()
		}
	}

	mutating func block() {
		while !parser.check(.rightBrace), !parser.check(.eof) {
			declaration()
		}

		parser.consume(.rightBrace, "Expected '}' after block.")
	}

	mutating func printStatement() {
		expression()
		parser.consume(.semicolon, "Expected ';' after value.")
		emit(.print)
	}

	mutating func ifStatement() {
		expression() // Add the if EXPRESSION to the stack

		let thenJumpLocation = emit(jump: .jumpIfFalse)
		emit(.pop) // Pop the condition off the stack

		parser.consume(.leftBrace, "Expected '{' before `if` statement.")
		block()

		let elseJump = emit(jump: .jump)

		// Backpack the jump
		patchJump(thenJumpLocation)
		emit(.pop) // Pop the condition off the stack

		if parser.match(.else) {
			statement()
		}

		patchJump(elseJump)
	}

	mutating func whileStatement() {
		// This is where we return to while the condition is true
		let loopStart = compilingChunk.count

		// Add the condition to the top of the stack
		expression()

		// Get the while condition
		parser.consume(.leftBrace, "Expected '{' after while condition")

		// Get the instruction to leave the loop
		let exitJump = emit(jump: .jumpIfFalse)
		emit(.pop) // Clean up the stack

		// The body of the loop
		block()
		emit(loop: loopStart)

		patchJump(exitJump)
		emit(.pop)
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

		declareVariable()

		if scopeDepth > 0 {
			return 0
		}

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
			error("Expected expression at line \(parser.previous.line).")
			return
		}

		let canAssign = precedence <= .assignment
		prefix(&self, canAssign)

		while precedence < parser.current.kind.rule.precedence {
			parser.advance()

			if let infix = parser.previous.kind.rule.infix {
				infix(&self, canAssign)
			}

			if canAssign, parser.match(.equal) {
				error("Syntax Error: Invalid target assignment", at: parser.previous)
			}
		}
	}

	// MARK: Prefix expressions

	mutating func grouping(_: Bool) {
		// Assume the initial "(" has been consumed
		expression()
		parser.consume(.rightParen, "Expected ')' after expression.")
	}

	mutating func number(_: Bool) {
		let lexeme = parser.previous.lexeme(in: source).reduce(into: "") { $0.append($1) }
		guard let value = Double(lexeme) else {
			error("Could not parse number: \(parser.previous.lexeme(in: source))")
			return
		}

		emit(constant: .number(value))
	}

	mutating func unary(_: Bool) {
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

	mutating func and(_: Bool) {
		let endJump = emit(jump: .jumpIfFalse)
		emit(.pop)
		parse(precedence: .and)
		patchJump(endJump)
	}

	mutating func or(_: Bool) {
		let elseJump = emit(jump: .jumpIfFalse)
		let endJump = emit(jump: .jump)

		patchJump(elseJump)
		emit(.pop)

		parse(precedence: .or)
		patchJump(endJump)
	}

	mutating func binary(_: Bool) {
		guard let kind = parser.previous?.kind else {
			error("No previous token for unary expr.")
			return
		}

		let rule = kind.rule
		parse(precedence: rule.precedence + 1)

		switch kind {
		case .plus: emit(.add)
		case .minus: emit(.subtract)
		case .star: emit(.multiply)
		case .slash: emit(.divide)
		case .equalEqual: emit(.equal)
		case .bangEqual: emit(.notEqual)
		case .less: emit(.less)
		case .lessEqual: emit(.greater, .not)
		case .greater: emit(.greater)
		case .greaterEqual: emit(.less, .not)
		default:
			() // Unreachable
		}
	}

	// MARK: Literals

	mutating func literal(_: Bool) {
		switch parser.previous.kind {
		case .false: emit(.false)
		case .true: emit(.true)
		case .nil: emit(.nil)
		default:
			() // Unreachable
		}
	}

	// TODO: add static string that we don't need to copy?
	mutating func string(_: Bool) {
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
		source[start ..< (start + length)].withUnsafeBufferPointer {
			for i in 0 ..< length {
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

	mutating func variable(_ canAssign: Bool) {
		namedVariable(parser.previous, canAssign)
	}

	// MARK: Helpers

	mutating func declareVariable() {
		if scopeDepth == 0 {
			return
		}

		if let name = parser.previous {
			var i = localCount
			while i >= 0 {
				guard let local = locals[i] else {
					i -= 1
					continue
				}

				if local.depth != -1, local.depth < scopeDepth {
					break
				}

				if name.same(lexeme: local.name, in: source) {
					error("Already a variable with this name in this scope")
				}

				i -= 1
			}

			addLocal(name: name)
		} else {
			error("No variable name at \(parser.current.line)")
		}
	}

	mutating func defineVariable(global: Byte) {
		if scopeDepth > 0 {
			markInitialized()
			return
		}

		emit(.defineGlobal)
		emit(global)
	}

	mutating func addLocal(name: Token) {
		if localCount == 256 {
			error("Too many local variables in function")
			return
		}

		locals[localCount] = Local(name: name, depth: scopeDepth)
		localCount += 1
	}

	mutating func markInitialized() {
		locals[localCount - 1]?.isInitialized = true
	}

	mutating func namedVariable(_ token: Token, _ canAssign: Bool) {
		let getOp, setOp: Opcode

		var arg: Byte? = resolveLocal(token)
		if arg != nil {
			getOp = .getLocal
			setOp = .setLocal
		} else {
			arg = identifierConstant(token)
			getOp = .getGlobal
			setOp = .setGlobal
		}

		guard let arg else {
			error("Could not get variable opcode", at: token)
			return
		}

		if canAssign, parser.match(.equal) {
			expression()
			emit(setOp)
			emit(arg)
		} else {
			emit(getOp)
			emit(arg)
		}
	}

	mutating func identifierConstant(_ token: Token) -> Byte {
		let value = Value.string(token.lexeme(in: source))
		return compilingChunk.write(constant: value)
	}

	mutating func withScope(perform: (inout Self) -> Void) {
		scopeDepth += 1
		perform(&self)
		scopeDepth -= 1

		// The block is done, gotta clean up the scope
		while localCount > 0, let local = locals[localCount - 1], local.depth > scopeDepth {
			emit(.pop)
			localCount -= 1
		}
	}

	mutating func resolveLocal(_ name: Token) -> Byte? {
		var i = localCount - 1 // Subtracting 1 because we're indexing into an array
		while i >= 0, let local = locals[i] {
			if name.same(lexeme: local.name, in: source) {
				guard local.isInitialized else {
					error("Cannot read local variable in its own initializer")
					return nil
				}

				return Byte(i)
			}

			i -= 1
		}

		return nil
	}

	mutating func uint16ToBytes(_ uint16: Int) -> (Byte, Byte) {
		let a = (uint16 >> 8) & 0xff
		let b = (uint16 & 0xff)

		return (Byte(a), Byte(b))
	}

	// MARK: Emitters

	mutating func emit(loop backToInstruction: Int) {
		emit(.loop)

		let offset = compilingChunk.count - backToInstruction + 2
		if offset > UInt16.max {
			error("Loop body too large, cmon.")
		}

		let (a, b) = uint16ToBytes(offset)
		emit(a, b)
	}

	mutating func emit(jump instruction: Opcode) -> Int {
		emit(instruction)

		// Use two bytes for the offset, which lets us jump over 65k bytes of code.
		// We'll fill these in with the patchJump later.
		emit(.uninitialized)
		emit(.uninitialized)

		// Return the current location of our chunk code, offset by 2 (since that's
		// where we're gonna store our offset.
		return compilingChunk.count - 2
	}

	mutating func patchJump(_ offset: Int) {
		// -2 to adjust for the bytecode for the jump offset itself
		let jump = compilingChunk.count - offset - 2
		if jump > UInt16.max {
			error("Too much code to jump over")
		}

		// Go back and replace the two placeholder bytes from emit(jump:)
		// the actual offset to jump over.
		let (a, b) = uint16ToBytes(jump)
		compilingChunk.code[offset] = a
		compilingChunk.code[offset + 1] = b
	}

	mutating func emit(constant value: consuming Value) {
		if compilingChunk.constants.count > UInt8.max {
			error("Too many constants in one chunk")
			return
		}

		compilingChunk.write(value: value, line: parser.previous?.line ?? -1)
	}

	mutating func emit(_ opcode: consuming Opcode) {
		emit(opcode.byte)
	}

	mutating func emit(_ opcode1: consuming Opcode, _ opcode2: consuming Opcode) {
		emit(opcode1)
		emit(opcode2)
	}

	mutating func emit(_ byte: consuming Byte) {
		compilingChunk.write(byte, line: parser.previous?.line ?? -1)
	}

	mutating func emit(_ byte1: consuming Byte, _ byte2: consuming Byte) {
		emit(byte1)
		emit(byte2)
	}

	mutating func error(_ message: String, at token: Token) {
		print("Compiler Error: \(message)")
		errors.append(Error(token: token, message: message))
	}

	mutating func error(_ message: String) {
		print("Compiler Error: \(message)")
		errors.append(Error(token: nil, message: message))
	}
}
