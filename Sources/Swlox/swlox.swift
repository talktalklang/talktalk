// The Swift Programming Language
// https://docs.swift.org/swift-book
//
// Swift Argument Parser
// https://swiftpackageindex.com/apple/swift-argument-parser/documentation

import ArgumentParser
import Foundation

@main
struct Swlox: ParsableCommand {
	@Argument(help: "The file to run.")
	var file: String?

	static var hadError = false

	static func error(_ message: String, line: Int) {
		report(line, "", message)
	}

	static func error(_ message: String, token: Token) {
		if token.kind == .eof {
			report(token.line, " at end", message)
		} else {
			report(token.line, "at '" + token.lexeme + "'", message)
		}
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
				try run(source: line)
			} catch {
				print("Error: \(error.localizedDescription)")
			}
		}
	}

	func run(source: String) throws {
		var scanner = Scanner(source: source)
		let tokens = scanner.scanTokens()
		var parser = Parser(tokens: tokens)

		try print(AstPrinter().print(expr: parser.expression()))
	}
}
