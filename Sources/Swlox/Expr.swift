protocol ExprVisitor {
	associatedtype Value

	func visit(_ expr: BinaryExpr) -> Value
	func visit(_ expr: GroupingExpr) -> Value
	func visit(_ expr: LiteralExpr) -> Value
	func visit(_ expr: UnaryExpr) -> Value
}

protocol Expr {
	func accept<Visitor: ExprVisitor>(visitor: Visitor) -> Visitor.Value
}

struct BinaryExpr: Expr {
	let lhs: any Expr
	let op: Token
	let rhs: any Expr

	func accept<Visitor: ExprVisitor>(visitor: Visitor) -> Visitor.Value {
		visitor.visit(self)
	}
}

struct GroupingExpr: Expr {
	let expr: any Expr

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

struct UnaryExpr: Expr {
	let op: Token
	let expr: any Expr

	func accept<Visitor: ExprVisitor>(visitor: Visitor) -> Visitor.Value {
		visitor.visit(self)
	}
}
