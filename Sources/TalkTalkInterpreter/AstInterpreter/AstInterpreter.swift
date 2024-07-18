struct AstInterpreter {
	var lastExpressionValue: Value = .nil
	var globals = Environment()
	var locals: [String: Int] = [:]
	var environment: Environment
	var output: any Output

	init(output: any Output) {
		self.environment = globals
		self.output = output

		// Define builtins
		defineClock()
	}

	mutating func run(_ statements: [any Stmt], onComplete: ((Value) -> Void)? = nil) {
		do {
			for statement in statements {
				try execute(statement: statement)
				onComplete?(lastExpressionValue)
			}
		} catch let error as RuntimeError {
			switch error {
			case let .nameError(message, token):
				TalkTalkInterpreter.runtimeError(message, token: token)
			case let .typeError(message, token):
				TalkTalkInterpreter.runtimeError(message, token: token)
			case let .assignmentError(message):
				TalkTalkInterpreter.runtimeError(message, token: .init(kind: .equal, lexeme: "=", line: -1))
			}
		} catch {
			output.print("RuntimeError: \(error)")
		}
	}

	func lookupVariable(_ name: Token, expr: any Expr) throws -> Value {
		do {
			if let distance = locals[expr.id] {
				return try environment.lookup(name: name, depth: distance)
			} else {
				return globals.lookup(name: name.lexeme) ?? .unknown
			}
		} catch {
			output.print("Locals: \(locals.debugDescription)")
			throw error
		}
	}

	func withEnvironment<T>(callback: (Environment) throws -> T) throws -> T {
		try callback(Environment(parent: environment))
	}

	mutating func execute(statement: any Stmt) throws {
		try statement.accept(visitor: &self)
	}

	mutating func resolve(_ expr: any Expr, depth: Int) {
		locals[expr.id] = depth
	}

	func isTruthy(_ value: Value) -> Bool {
		switch value {
		case .string:
			true
		case .number:
			true
		case .callable:
			true
		case .class:
			true
		case let .bool(bool):
			bool
		case .nil:
			false
		case .unknown:
			false
		case .void:
			fatalError("void no")
		default:
			true
		}
	}

	mutating func evaluate(_ expr: any Expr) throws -> Value {
		lastExpressionValue = try expr.accept(visitor: &self)
		return lastExpressionValue
	}
}
