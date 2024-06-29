struct AstInterpreter {
	var lastExpressionValue: Value = .nil
	let globals = Environment()
	var environmentStack: [Environment] = []

	init() {
		environmentStack = [globals]
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

	mutating func execute(statement: any Stmt) throws {
		try statement.accept(visitor: &self)
	}

	func isTruthy(_ value: Value) -> Bool {
		switch value {
		case .string(_):
			true
		case .number(_):
			true
		case .bool(let bool):
			bool
		case .nil:
			false
		case .unknown:
			false
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

