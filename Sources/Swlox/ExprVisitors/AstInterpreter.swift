enum Value {
	case string(String),
			 number(Double),
			 bool(Bool),
			 `nil`,
			 unknown
}

struct Environment {
	var vars: [String: Value] = [:]

	mutating func assign(_ value: Value, to name: String) throws {
		guard vars.index(forKey: name) != nil else {
			throw RuntimeError.assignmentError("Cannot assign to uninitialized variable")
		}

		vars[name] = value
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
				Swlox.runtimeError(message, token: token)
			case let .typeError(message, token):
				Swlox.runtimeError(message, token: token)
			case let .assignmentError(message):
				Swlox.runtimeError(message, token: .init(kind: .equal, lexeme: "=", line: -1))
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
		guard let value = environment.vars[expr.name.lexeme] else {
			throw RuntimeError.nameError("undefined variable", expr.name)
		}

		return value
	}
	
	mutating func visit(_ expr: AssignExpr) throws -> Value {
		let value = try evaluate(expr.value)
		try environment.assign(value, to: expr.name.lexeme)
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
			environment.vars[stmt.name] = try evaluate(initializer)
		} else {
			environment.vars[stmt.name] = .unknown
		}
	}
}
