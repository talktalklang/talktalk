struct AstPrinter: ExprVisitor {
	func print(expr: any Expr) -> String {
		expr.accept(visitor: self)
	}

	func parenthesize(_ name: String, _ exprs: (any Expr)...) -> String {
		var parts = ["(", name]

		for expr in exprs {
			parts.append(expr.accept(visitor: self))
			parts.append(" ")
		}

		parts.append(")")

		return parts.joined(separator: "")
	}

	func visit(_ expr: BinaryExpr) -> String {
		parenthesize(expr.op.description, expr.lhs, expr.rhs)
	}

	func visit(_ expr: GroupingExpr) -> String {
		parenthesize("grouping", expr.expr)
	}

	func visit(_ expr: LiteralExpr) -> String {
		expr.literal.lexeme.trimmingCharacters(in: .whitespacesAndNewlines)
	}

	func visit(_ expr: UnaryExpr) -> String {
		parenthesize(expr.op.lexeme, expr.expr)
	}
}
