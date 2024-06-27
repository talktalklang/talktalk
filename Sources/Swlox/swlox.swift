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
		hadError = true
		report(line, "", message)
	}

	static func report(_ line: Int, _ location: String, _ message: String) {
		print("[line \(line)] Error\(location): \(message)")
	}

	mutating func run() throws {
		if let file {
			runFile(file: file)
		} else {
			runPrompt()
		}
	}

	func runFile(file: String) {
		let source = try! String(contentsOfFile: file)
		run(source: source)
	}

	func runPrompt() {
		let expr = BinaryExpr(
			lhs: UnaryExpr(op: .init(kind: .minus, lexeme: "-", line: 2), expr: LiteralExpr(literal: .init(kind: .number(1), lexeme: "1", line: 1))),
			op: .init(kind: .lessEqual, lexeme: "<=", line: 1),
			rhs: UnaryExpr(op: .init(kind: .minus, lexeme: "-", line: 2), expr: LiteralExpr(literal: .init(kind: .number(3), lexeme: "3", line: 1)))
		)

		print(AstPrinter().visit(expr))


		while true {
			print("> ", terminator: "")
			guard let line = readLine() else {
				break
			}

			run(source: line)
		}
	}

	func run(source: String) {
		var scanner = Scanner(source: source)
		let tokens = scanner.scanTokens()
		var parser = Parser(tokens: tokens)

		try! print(AstPrinter().print(expr: parser.expression()))
	}
}
