struct AstPrinter: ExprVisitor {
	mutating func print(expr: any Expr) throws -> String {
		try expr.accept(visitor: &self)
	}

	mutating func parenthesize(_ name: String, _ exprs: [any Expr]) throws -> String {
		var parts = ["(", name]

		for expr in exprs {
			try parts.append(expr.accept(visitor: &self))
			parts.append(" ")
		}

		parts.append(")")

		return parts.joined(separator: "")
	}

	mutating func parenthesize(_ name: String, _ exprs: (any Expr)...) throws -> String {
		return try parenthesize(name, exprs)
	}

	mutating func visit(_ expr: BinaryExpr) throws -> String {
		try parenthesize(expr.op.description, expr.lhs, expr.rhs)
	}

	mutating func visit(_ expr: GroupingExpr) throws -> String {
		try parenthesize("grouping", expr.expr)
	}

	mutating func visit(_ expr: LiteralExpr) throws -> String {
		expr.literal.lexeme.trimmingCharacters(in: .whitespacesAndNewlines)
	}

	mutating func visit(_ expr: UnaryExpr) throws -> String {
		try parenthesize(expr.op.lexeme, expr.expr)
	}

	mutating func visit(_ expr: VariableExpr) throws -> String {
		expr.name.lexeme
	}

	mutating func visit(_ expr: AssignExpr) throws -> String {
		try parenthesize("=", expr.value)
	}

	mutating func visit(_ expr: LogicExpr) throws -> String {
		try parenthesize(expr.op.lexeme, expr.lhs, expr.rhs)
	}

	mutating func visit(_ expr: CallExpr) throws -> String {
		try parenthesize(self.print(expr: expr.callee), expr.arguments)
	}

	mutating func visit(_ expr: GetExpr) throws -> String {
		".\(expr.name)"
	}

	mutating func visit(_ expr: SetExpr) throws -> String {
		".\(expr.name) = \(expr.value)"
	}

	mutating func visit(_ expr: SelfExpr) throws -> String {
		"self"
	}
}
