// The Swift Programming Language
// https://docs.swift.org/swift-book
//
// Swift Argument Parser
// https://swiftpackageindex.com/apple/swift-argument-parser/documentation

import ArgumentParser
import Foundation

enum RuntimeError: Error {
	case typeError(String, Token),
	     nameError(String, Token),
	     assignmentError(String)
}

@main
struct TalkTalk: ParsableCommand {
	@Argument(help: "The input to run.")
	var input: String?

	@Flag(help: "Just print the tokens") var tokenize: Bool = false

	nonisolated(unsafe) static var hadError = false
	nonisolated(unsafe) static var hadRuntimeError = false

	static func error(_ message: String, line: Int) {
		report(line, "", message)
	}

	static func error(_ message: String, token: Token) {
		if token.kind == .eof {
			report(token.line, " at end", message)
		} else {
			report(token.line, " at '" + token.lexeme + "'", message)
		}
	}

	static func runtimeError(_ message: String, token: Token) {
		hadRuntimeError = true
		error(message, token: token)
	}

	static func report(_ line: Int, _ location: String, _ message: String) {
		hadError = true
		print("[line \(line)] Error\(location): \(message)")
	}

	mutating func run() throws {
		if let input {
			if FileManager.default.fileExists(atPath: input) {
				try runFile(file: input)
			} else {
				var interpreter = AstInterpreter()
				try run(source: input, in: &interpreter)
			}
		} else {
			runPrompt()
		}
	}

	func runFile(file: String) throws {
		let source = try! String(contentsOfFile: file)
		var interpreter = AstInterpreter()
		try run(source: source, in: &interpreter)
	}

	func runPrompt() {
		var interpreter = AstInterpreter()

		while true {
			print("> ", terminator: "")
			guard let line = readLine() else {
				break
			}

			do {
				try run(source: line, in: &interpreter) { value in
					print("=> \(value)")
				}
			} catch {}
		}
	}

	func run(source: String, in interpreter: inout AstInterpreter, onComplete: ((Value) -> Void)? = nil) throws {
		var scanner = Scanner(source: source)
		let tokens = scanner.scanTokens()

		if tokenize {
			for token in tokens {
				print(token)
			}

			return
		}

		var parser = Parser(tokens: tokens)
		let parsed = try parser.parse()

		var resolver = AstResolver(interpreter: interpreter)
		var interpreter = try resolver.resolve(parsed)

		interpreter.run(parsed, onComplete: onComplete)
	}
}
