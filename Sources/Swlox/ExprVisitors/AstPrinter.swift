struct AstPrinter: ExprVisitor {
	func print(expr: some Expr) -> String {
		expr.accept(visitor: self)
	}

	func parenthesize(_ name: String, _ exprs: (any Expr)...) -> String {
		var parts = ["(", name, " "]

		for expr in exprs {
			parts.append(expr.accept(visitor: self))
		}

		parts.append(")")

		return parts.joined(separator: "")
	}

	func visit<LHS, RHS>(_ expr: BinaryExpr<LHS, RHS>) -> String {
		parenthesize(expr.op.description, expr.lhs, expr.rhs)
	}

	func visit<Expression>(_ expr: GroupingExpr<Expression>) -> String {
		parenthesize("grouping", expr)
	}

	func visit(_ expr: LiteralExpr) -> String {
		expr.literal.lexeme
	}

	func visit<Expression: Expr>(_ expr: UnaryExpr<Expression>) -> String {
		parenthesize(expr.op.lexeme, expr.expr)
	}
}
