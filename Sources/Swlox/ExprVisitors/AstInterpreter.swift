struct AstInterpreter {
	enum Value {
		case string(String),
		     number(Double),
		     bool(Bool),
				 `nil`,
		     unknown
	}

	var lastExpressionValue: Value = .nil

	mutating func run(_ statements: [any Stmt]) {
		do {
			for statement in statements {
				try execute(statement: statement)
				print("=> \(lastExpressionValue)")
			}
		} catch let RuntimeError.typeError(message, token) {
			Swlox.runtimeError(message, token: token)
		} catch {
			fatalError("Unhandled error: \(error)")
		}
	}

	mutating func execute(statement: any Stmt) throws {
		try statement.accept(visitor: &self)
	}
}

extension AstInterpreter: ExprVisitor {
	mutating func visit(_ expr: LiteralExpr) throws -> Value {
		switch expr.literal.kind {
		case .number(let number):
			.number(number)
		case .string(let string):
			.string(string)
		case .true:
			.bool(true)
		case .false:
			.bool(false)
		case .nil:
			.nil
		default:
			.unknown
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
}
