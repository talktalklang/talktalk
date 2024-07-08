//
//  Compiler.swift
//
//
//  Created by Pat Nakajima on 7/1/24.
//
import Foundation

public final class Compiler {
	enum Errors: Swift.Error {
		case errors([TalkTalk.Error])
	}

	public struct Error: Sendable {
		var token: Token?
		var message: String

		public func description(in compiler: Compiler) -> String {
			if let token {
				"""
				\(message) at \(token.start), line: \(token.line)

				\t\(compiler.parser.line(token.line))

				"""
			} else {
				"\(message)"
			}
		}
	}

	var parent: Compiler?
	var parser: Parser
	var function: Function
	var currentClass: ClassCompiler?

	public var errors: [Error] = []

	// MARK: Local variable management

	var locals = ContiguousArray<Local?>(repeating: nil, count: 256)
	var localCount = 1 // Reserve local count spot 0 for internal use
	var scopeDepth = 0
	var upvalues: [Upvalue] = []

	func load(source: String) {

	}

	// MARK: Debuggy

	#if DEBUG
		var parserRepeats: [Int: Int] = [:]

		func checkForInfiniteLoop() {
			parserRepeats[parser.current.start, default: 0] += 1

			if parserRepeats[parser.current.start]! > 100 {
				fatalError("Probably an infinite loop goin pat.")
			}
		}
	#endif

	init(parent: Compiler, kind: Function.Kind) {
		self.parent = parent
		self.parser = parent.parser
		self.function = Function(arity: 0, chunk: Chunk(), name: "", kind: kind)

		if kind != .function {
			locals[0] = Local(name: .synthetic(.self, length: 4), depth: 0)
		} else {
			locals[0] = Local(name: .synthetic(.self, length: 4), depth: 0)
		}
	}

	public init(source: String) {
		var headers = try! String(contentsOf: Bundle.module.url(forResource: "Array", withExtension: "tlk")!)

		self.parser = Parser(lexer: Lexer(source: headers + "\n" + source))
		self.function = Function(arity: 0, chunk: Chunk(), name: "main", kind: .main)
		locals[0] = Local(name: parser.current, depth: 0)
	}

	var chunk: Chunk {
		get {
			function.chunk
		}

		set {
			function.chunk = newValue
		}
	}

	var source: ContiguousArray<Character> {
		parser.lexer.source
	}

	public func compile() throws {
		while parser.current.kind != .eof {
			declaration()

			#if DEBUG
				checkForInfiniteLoop()
			#endif
		}

		if collectErrors().isEmpty {
			emit(opcode: .nil)
			emit(opcode: .return)
			return
		}

		throw Errors.errors(collectErrors())
	}

	// MARK: Statements

	func block() {
		while !parser.check(.rightBrace), !parser.check(.eof) {
			declaration()
		}

		parser.consume(.rightBrace, "Expected '}' after block.")
	}

	func expression() {
		parse(precedence: .assignment)
	}

	func parseVariable(_ message: String) -> Byte {
		parser.consume(.identifier, message)

		declareVariable()

		if scopeDepth > 0 {
			return 0
		}

		return identifierConstant(parser.previous)
	}

	// Starting with parser.current, parse expressions at `precedence`
	// level or higher.
	func parse(precedence: Parser.Precedence) {
		parser.advance()

		let opKind = parser.previous.kind
		let rule = opKind.rule

		guard let prefix = rule.prefix else {
			error("Expected expression at line \(parser.previous.line):\n\n\t\(parser.line(parser.previous.line))\n")

			return
		}

		let canAssign = precedence <= .assignment
		prefix(self, canAssign)

		while precedence < parser.current.kind.rule.precedence {
			#if DEBUG
				checkForInfiniteLoop()
			#endif

			parser.advance()

			if let infix = parser.previous.kind.rule.infix {
				infix(self, canAssign)
			}

			if canAssign, parser.match(.equal) {
				error("Syntax Error: Invalid target assignment", at: parser.previous)
			}
		}
	}

	func uint16ToBytes(_ uint16: Int) -> (Byte, Byte) {
		let a = (uint16 >> 8) & 0xFF
		let b = (uint16 & 0xFF)

		return (Byte(a), Byte(b))
	}

	// MARK: Emitters

	func emit(loop backToInstruction: Int) {
		emit(opcode: .loop)

		let offset = chunk.count - backToInstruction + 2
		if offset > UInt16.max {
			error("Loop body too large, cmon.")
		}

		let (a, b) = uint16ToBytes(offset)
		emit(a, b)
	}

	func emit(jump instruction: Opcode) -> Int {
		emit(opcode: instruction)

		// Use two bytes for the offset, which lets us jump over 65k bytes of code.
		// We'll fill these in with the patchJump later.
		emit(opcode: .uninitialized)
		emit(opcode: .uninitialized)

		// Return the current location of our chunk code, offset by 2 (since that's
		// where we're gonna store our offset.
		return chunk.count - 2
	}

	func patchJump(_ offset: Int) {
		// -2 to adjust for the bytecode for the jump offset itself
		let jump = chunk.count - offset - 2
		if jump > UInt16.max {
			error("Too much code to jump over")
		}

		// Go back and replace the two placeholder bytes from emit(jump:)
		// the actual offset to jump over.
		let (a, b) = uint16ToBytes(jump)
		chunk.code[offset] = a
		chunk.code[offset + 1] = b
	}

	func emit(constant value: Value) {
		if chunk.constants.count > UInt8.max {
			error("Too many constants in one chunk")
			return
		}

		chunk.write(value: value, line: parser.previous?.line ?? -1)
	}

	func emit(opcode: Opcode) {
		emit(opcode.byte)
	}

	func emit(_ opcode1: Opcode, _ opcode2: Opcode) {
		emit(opcode: opcode1)
		emit(opcode: opcode2)
	}

	func emit(_ byte: Byte) {
		chunk.write(byte, line: parser.previous?.line ?? -1)
	}

	func emit(_ byte1: Byte, _ byte2: Byte) {
		emit(byte1)
		emit(byte2)
	}

	func emitReturn() {
		emit(opcode: .nil)
		emit(opcode: .return)
	}

	func collectErrors() -> [TalkTalk.Error] {
		var result: [TalkTalk.Error] = []

		if !errors.isEmpty {
			result.append(.compiler(errors))
		}

		if !parser.errors.isEmpty {
			result.append(.parser(parser.errors))
		}

		return result
	}

	func error(_ message: String, at token: Token) {
		if let parent {
			parent.error(message, at: token)
		} else {
			errors.append(Error(token: token, message: message))
		}
	}

	func error(_ message: String) {
		if let parent {
			parent.error(message)
		} else {
			errors.append(Error(token: nil, message: message))
		}
	}
}
