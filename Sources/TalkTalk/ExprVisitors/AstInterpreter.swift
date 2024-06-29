struct AstInterpreter {
	var lastExpressionValue: Value = .nil
	var globals = Environment()
	var environmentStack: [Environment] = []

	init() {
		environmentStack = [globals]

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
				TalkTalk.runtimeError(message, token: token)
			case let .typeError(message, token):
				TalkTalk.runtimeError(message, token: token)
			case let .assignmentError(message):
				TalkTalk.runtimeError(message, token: .init(kind: .equal, lexeme: "=", line: -1))
			}
		} catch {
			print("RuntimeError: \(error)")
		}
	}

	func withEnvironment<T>(callback: (Environment) throws -> T) throws -> T {
		try callback(Environment(parent: environment))
	}

	mutating func execute(statement: any Stmt) throws {
		try statement.accept(visitor: &self)
	}

	func isTruthy(_ value: Value) -> Bool {
		switch value {
		case .string(_):
			true
		case .number(_):
			true
		case .callable(_):
			true
		case .bool(let bool):
			bool
		case .nil:
			false
		case .unknown:
			false
		case .void:
			fatalError("void no")
		}
	}

	mutating func evaluate(_ expr: any Expr) throws -> Value {
		lastExpressionValue = try expr.accept(visitor: &self)
		return lastExpressionValue
	}

	var environment: Environment {
		environmentStack.last!
	}
}

