protocol ExprVisitor {
	associatedtype Value

	func visit<LHS: Expr, RHS: Expr>(_ expr: BinaryExpr<LHS, RHS>) -> Value
	func visit<Expression: Expr>(_ expr: GroupingExpr<Expression>) -> Value
	func visit(_ expr: LiteralExpr) -> Value
	func visit<Expression: Expr>(_ expr: UnaryExpr<Expression>) -> Value
}

protocol Expr {
	func accept<Visitor: ExprVisitor>(visitor: Visitor) -> Visitor.Value
}

struct BinaryExpr<LHS: Expr, RHS: Expr>: Expr {
	let lhs: LHS
	let op: Token
	let rhs: RHS

	func accept<Visitor: ExprVisitor>(visitor: Visitor) -> Visitor.Value {
		visitor.visit(self)
	}
}

struct GroupingExpr<Expression: Expr>: Expr {
	let expr: Expression

	func accept<Visitor: ExprVisitor>(visitor: Visitor) -> Visitor.Value {
		visitor.visit(self)
	}
}

struct LiteralExpr: Expr {
	let literal: Token

	func accept<Visitor: ExprVisitor>(visitor: Visitor) -> Visitor.Value {
		visitor.visit(self)
	}
}

struct UnaryExpr<Expression: Expr>: Expr {
	let op: Token
	let expr: Expression

	func accept<Visitor: ExprVisitor>(visitor: Visitor) -> Visitor.Value {
		visitor.visit(self)
	}
}
