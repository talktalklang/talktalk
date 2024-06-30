extension AstInterpreter: ExprVisitor {
	mutating func visit(_ expr: VariableExpr) throws -> Value {
		return try lookupVariable(expr.name, expr: expr)
	}

	mutating func visit(_ expr: AssignExpr) throws -> Value {
		let value = try evaluate(expr.value)
		let distance = locals[expr.id]

		if let distance {
			try environment.assign(name: expr.name, value: value, depth: distance)
		} else {
			_ = try globals.assign(name: expr.name.lexeme, value: value)
		}

		return value
	}

	mutating func visit(_ expr: LiteralExpr) throws -> Value {
		switch expr.literal.kind {
		case let .number(number):
			return .number(number)
		case let .string(string):
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
			   case let .number(rhs) = rhs
			{
				return .number(lhs - rhs)
			}
		case .plus:
			if case let .number(lhs) = lhs,
			   case let .number(rhs) = rhs
			{
				return .number(lhs + rhs)
			} else if case let .string(lhs) = lhs,
			          case let .string(rhs) = rhs
			{
				return .string(lhs + rhs)
			}
		case .slash:
			if case let .number(lhs) = lhs,
			   case let .number(rhs) = rhs
			{
				return .number(lhs / rhs)
			}
		case .star:
			if case let .number(lhs) = lhs,
			   case let .number(rhs) = rhs
			{
				return .number(lhs * rhs)
			}
		case .equalEqual:
			if case let .number(lhs) = lhs,
			   case let .number(rhs) = rhs
			{
				return .bool(lhs == rhs)
			}
		case .greater:
			if case let .number(lhs) = lhs,
			   case let .number(rhs) = rhs
			{
				return .bool(lhs > rhs)
			}
		case .greaterEqual:
			if case let .number(lhs) = lhs,
			   case let .number(rhs) = rhs
			{
				return .bool(lhs >= rhs)
			}
		case .less:
			if case let .number(lhs) = lhs,
			   case let .number(rhs) = rhs
			{
				return .bool(lhs < rhs)
			}
		case .lessEqual:
			if case let .number(lhs) = lhs,
			   case let .number(rhs) = rhs
			{
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

		return try callee.call(&self, arguments)
	}

	mutating func visit(_ expr: GetExpr) throws -> Value {
		let receiver = try evaluate(expr.receiver)

		guard case let .instance(instance) = receiver else {
			throw RuntimeError.typeError("\(receiver) has no property: \(expr.name.lexeme)", expr.name)
		}

		return instance.get(expr.name)
	}

	mutating func visit(_ expr: SetExpr) throws -> Value {
		let receiver = try evaluate(expr.receiver)

		guard case let .instance(instance) = receiver else {
			throw RuntimeError.typeError("\(receiver) has no property: \(expr.name.lexeme)", expr.name)
		}

		let value = try evaluate(expr.value)
		instance.set(expr.name, value: value)

		return value
	}
}
