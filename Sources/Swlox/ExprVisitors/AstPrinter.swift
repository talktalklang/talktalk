struct AstPrinter: ExprVisitor {
	mutating func print(expr: any Expr) throws -> String {
		try expr.accept(visitor: &self)
	}

	mutating func parenthesize(_ name: String, _ exprs: (any Expr)...) throws -> String {
		var parts = ["(", name]

		for expr in exprs {
			try parts.append(expr.accept(visitor: &self))
			parts.append(" ")
		}

		parts.append(")")

		return parts.joined(separator: "")
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
}
