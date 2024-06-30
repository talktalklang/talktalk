import Foundation

enum RuntimeError: Error {
	case typeError(String, Token),
	     nameError(String, Token),
	     assignmentError(String)
}

public protocol Output: AnyObject {
	func print(_ output: Any...)
	func print(_ output: Any..., terminator: String)
}

public final class StdoutOutput: Output {
	public func print(_ output: Any...) {
		Swift.print(output)
	}

	public func print(_ output: Any..., terminator: String = "\n") {
		Swift.print(output, terminator: terminator)
	}

	public init() {}
}

public struct TalkTalkInterpreter {
	var input: String?
	var tokenize: Bool = false
	var output: any Output = StdoutOutput()

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

	public init(input: String? = nil, tokenize: Bool, output: any Output = StdoutOutput()) {
		self.input = input
		self.tokenize = tokenize
		self.output = output
	}

	public mutating func run() throws {
		if let input {
			if FileManager.default.fileExists(atPath: input) {
				try runFile(file: input)
			} else {
				var interpreter = AstInterpreter(output: output)
				try run(source: input, in: &interpreter)
			}
		} else {
			runPrompt()
		}
	}

	public func runFile(file: String) throws {
		let source = try! String(contentsOfFile: file)
		var interpreter = AstInterpreter(output: output)
		try run(source: source, in: &interpreter)
	}

	public func runPrompt() {
		var interpreter = AstInterpreter(output: output)

		while true {
			output.print("> ", terminator: "")
			guard let line = readLine() else {
				break
			}

			do {
				try run(source: line, in: &interpreter) { value in
					output.print("=> \(value)")
				}
			} catch {}
		}
	}

	func run(source: String, in interpreter: inout AstInterpreter, onComplete: ((Value) -> Void)? = nil) throws {
		var scanner = Scanner(source: source)
		let tokens = scanner.scanTokens()

		if tokenize {
			for token in tokens {
				output.print(token)
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
