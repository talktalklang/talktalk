// The Swift Programming Language
// https://docs.swift.org/swift-book
//
// Swift Argument Parser
// https://swiftpackageindex.com/apple/swift-argument-parser/documentation

import ArgumentParser
import Foundation

enum RuntimeError: Error {
	case typeError(String, Token)
}

@main
struct Swlox: ParsableCommand {
	@Argument(help: "The file to run.")
	var file: String?

	@Flag(help: "Just print the tokens") var tokenize: Bool = false

	static var hadError = false
	static var hadRuntimeError = false

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
		if let file {
			try runFile(file: file)
		} else {
			runPrompt()
		}
	}

	func runFile(file: String) throws {
		let source = try! String(contentsOfFile: file)
		try run(source: source)
	}

	func runPrompt() {
		while true {
			print("> ", terminator: "")
			guard let line = readLine() else {
				break
			}

			do {
				try run(source: line, repl: true)
			} catch {
				print("Error: \(error.localizedDescription)")
			}
		}
	}

	func run(source: String, repl: Bool = false) throws {
		var scanner = Scanner(source: source)
		let tokens = scanner.scanTokens()

		if tokenize {
			for token in tokens {
				print(token)
			}

			return
		}

		var parser = Parser(tokens: tokens)
		var interpreter = AstInterpreter()

		try interpreter.run(parser.parse(), repl: repl)
	}
}
