// TODO: It'd be nice to not have all these existentials everywhere
protocol ExprVisitor {
	associatedtype Value

	mutating func visit(_ expr: BinaryExpr) throws -> Value
	mutating func visit(_ expr: GroupingExpr) throws -> Value
	mutating func visit(_ expr: LiteralExpr) throws -> Value
	mutating func visit(_ expr: UnaryExpr) throws -> Value
	mutating func visit(_ expr: VariableExpr) throws -> Value
	mutating func visit(_ expr: AssignExpr) throws -> Value
}

protocol Expr {
	func accept<Visitor: ExprVisitor>(visitor: inout Visitor) throws -> Visitor.Value
}

struct BinaryExpr: Expr {
	let lhs: any Expr
	let op: Token
	let rhs: any Expr

	func accept<Visitor: ExprVisitor>(visitor: inout Visitor) throws -> Visitor.Value {
		try visitor.visit(self)
	}
}

struct GroupingExpr: Expr {
	let expr: any Expr

	func accept<Visitor: ExprVisitor>(visitor: inout Visitor) throws -> Visitor.Value {
		try visitor.visit(self)
	}
}

struct LiteralExpr: Expr {
	let literal: Token

	func accept<Visitor: ExprVisitor>(visitor: inout Visitor) throws -> Visitor.Value {
		try visitor.visit(self)
	}
}

struct UnaryExpr: Expr {
	let op: Token
	let expr: any Expr

	func accept<Visitor: ExprVisitor>(visitor: inout Visitor) throws -> Visitor.Value {
		try visitor.visit(self)
	}
}

struct VariableExpr: Expr {
	let name: Token

	func accept<Visitor: ExprVisitor>(visitor: inout Visitor) throws -> Visitor.Value {
		try visitor.visit(self)
	}
}

struct AssignExpr: Expr {
	let name: Token
	let value: any Expr

	func accept<Visitor: ExprVisitor>(visitor: inout Visitor) throws -> Visitor.Value {
		try visitor.visit(self)
	}
}
