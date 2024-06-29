enum Value: Equatable {
	enum CallError: Error {
		case valueNotCallable(Value)
	}

	case string(String),
			 number(Double),
			 bool(Bool),
			 `nil`,
			 unknown

	func call(_ interpreter: AstInterpreter, _ arguments: [Value]) throws -> Value {
		throw CallError.valueNotCallable(self)
	}
}

class Environment {
	enum AssignmentResult {
		case handled, unhandled, uninitialized
	}

	private var vars: [String: Value] = [:]
	private var parent: Environment?

	init(parent: Environment? = nil) {
		self.parent = parent
	}

	func lookup(name: String) -> Value? {
		vars[name] ?? parent?.lookup(name: name)
	}

	func initialize(name: String, value: Value) {
		vars[name] = value
	}

	func assign(name: String, value: Value) throws -> AssignmentResult {
		if try parent?.assign(name: name, value: value) == .handled {
			return .handled
		}

		guard lookup(name: name) != nil else {
			throw RuntimeError.assignmentError("Cannot assign to uninitialized variable")
		}

		vars[name] = value

		return .handled
	}
}

struct AstInterpreter {
	var lastExpressionValue: Value = .nil
	var environment = Environment()

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
}

extension AstInterpreter: ExprVisitor {
	mutating func visit(_ expr: VariableExpr) throws -> Value {
		guard let value = environment.lookup(name: expr.name.lexeme) else {
			throw RuntimeError.nameError("undefined variable", expr.name)
		}

		return value
	}

	mutating func visit(_ expr: AssignExpr) throws -> Value {
		let value = try evaluate(expr.value)
		_ = try environment.assign(name: expr.name.lexeme, value: value)
		return value
	}

	mutating func visit(_ expr: LiteralExpr) throws -> Value {
		switch expr.literal.kind {
		case .number(let number):
			return .number(number)
		case .string(let string):
			return .string(string)
		case .true:
			return .bool(true)
		case .false:
			return .bool(false)
		case .nil:
			return .nil
		default:
			return .unknown
		}
	}

	mutating func visit(_ expr: LogicExpr) throws -> Value {
		let lhs = try evaluate(expr.lhs)

		if expr.op.kind == .pipePipe {
			if isTruthy(lhs) { return lhs }
		} else {
			if !isTruthy(lhs) { return lhs }
		}

		return try evaluate(expr.rhs)
	}

	mutating func visit(_ expr: BinaryExpr) throws -> Value {
		let lhs = try evaluate(expr.lhs)
		let rhs = try evaluate(expr.rhs)

		switch expr.op.kind {
		case .minus:
			if case let .number(lhs) = lhs,
				 case let .number(rhs) = rhs {
				return .number(lhs - rhs)
			}
		case .plus:
			if case let .number(lhs) = lhs,
				 case let .number(rhs) = rhs {
				return .number(lhs + rhs)
			}
		case .slash:
			if case let .number(lhs) = lhs,
				 case let .number(rhs) = rhs {
				return .number(lhs / rhs)
			}
		case .star:
			if case let .number(lhs) = lhs,
				 case let .number(rhs) = rhs {
				return .number(lhs * rhs)
			}
		case .equalEqual:
			if case let .number(lhs) = lhs,
				 case let .number(rhs) = rhs {
				return .bool(lhs == rhs)
			}
		case .greater:
			if case let .number(lhs) = lhs,
				 case let .number(rhs) = rhs {
				return .bool(lhs > rhs)
			}
		case .greaterEqual:
			if case let .number(lhs) = lhs,
				 case let .number(rhs) = rhs {
				return .bool(lhs >= rhs)
			}
		case .less:
			if case let .number(lhs) = lhs,
				 case let .number(rhs) = rhs {
				return .bool(lhs < rhs)
			}
		case .lessEqual:
			if case let .number(lhs) = lhs,
				 case let .number(rhs) = rhs {
				return .bool(lhs <= rhs)
			}
		default:
			()
		}

		return .unknown
	}

	mutating func visit(_ expr: GroupingExpr) throws -> Value {
		try evaluate(expr.expr)
	}

	mutating func visit(_ expr: UnaryExpr) throws -> Value {
		let rhs = try evaluate(expr.expr)

		switch expr.op.kind {
		case .minus:
			if case let .number(number) = rhs {
				return .number(-number)
			}
		case .bang:
			return .bool(!isTruthy(rhs))
		default:
			()
		}

		return .unknown
	}

	mutating func visit(_ expr: CallExpr) throws -> Value {
		let callee = try evaluate(expr.callee)
		var arguments: [Value] = []

		for argument in expr.arguments {
			try arguments.append(evaluate(argument))
		}

		return try callee.call(self, arguments)
	}

	private func isTruthy(_ value: Value) -> Bool {
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

	private mutating func evaluate(_ expr: any Expr) throws -> Value {
		lastExpressionValue = try expr.accept(visitor: &self)
		return lastExpressionValue
	}
}

extension AstInterpreter: StmtVisitor {
	mutating func visit(_ stmt: PrintStmt) throws {
		try print(evaluate(stmt.expr))
	}

	mutating func visit(_ stmt: ExpressionStmt) throws {
		_ = try evaluate(stmt.expr)
	}

	mutating func visit(_ stmt: VarStmt) throws {
		if let initializer = stmt.initializer {
			environment.initialize(name: stmt.name, value: try evaluate(initializer))
		} else {
			environment.initialize(name: stmt.name, value: .nil)
		}
	}

	mutating func visit(_ stmt: BlockStmt) throws {
		try executeBlock(stmt.statements, environment: Environment(parent: environment))
	}

	mutating func visit(_ stmt: IfStmt) throws {
		if try isTruthy(evaluate(stmt.condition)) {
			try execute(statement: stmt.thenStatement)
		} else if let elseStatement = stmt.elseStatement {
			try execute(statement: elseStatement)
		}
	}

	mutating func visit(_ stmt: WhileStmt) throws {
		while try isTruthy(evaluate(stmt.condition)) {
			for statement in stmt.statements {
				try execute(statement: statement)
			}
		}
	}

	mutating func executeBlock(_ statements: [any Stmt], environment: Environment) throws {
		// TODO: Don't mutate environment
		let previous = self.environment

		defer {
			self.environment = previous
		}

		self.environment = environment

		for statement in statements {
			try	execute(statement: statement)
		}
	}
}
