// TODO: It'd be nice to not have all these existentials everywhere
protocol ExprVisitor {
	associatedtype Value

	mutating func visit(_ expr: BinaryExpr) throws -> Value
	mutating func visit(_ expr: GroupingExpr) throws -> Value
	mutating func visit(_ expr: LiteralExpr) throws -> Value
	mutating func visit(_ expr: UnaryExpr) throws -> Value
	mutating func visit(_ expr: VariableExpr) throws -> Value
	mutating func visit(_ expr: AssignExpr) throws -> Value
	mutating func visit(_ expr: LogicExpr) throws -> Value
	mutating func visit(_ expr: CallExpr) throws -> Value
	mutating func visit(_ expr: GetExpr) throws -> Value
	mutating func visit(_ expr: SetExpr) throws -> Value
	mutating func visit(_ expr: SelfExpr) throws -> Value
}

protocol Expr: Sendable, Identifiable {
	var id: String { get set }
	func accept<Visitor: ExprVisitor>(visitor: inout Visitor) throws -> Visitor.Value
}

struct BinaryExpr: Expr {
	var id: String
	let lhs: any Expr
	let op: Token
	let rhs: any Expr

	func accept<Visitor: ExprVisitor>(visitor: inout Visitor) throws -> Visitor.Value {
		try visitor.visit(self)
	}
}

struct GroupingExpr: Expr {
	var id: String
	let expr: any Expr

	func accept<Visitor: ExprVisitor>(visitor: inout Visitor) throws -> Visitor.Value {
		try visitor.visit(self)
	}
}

struct LiteralExpr: Expr {
	var id: String
	let literal: Token

	func accept<Visitor: ExprVisitor>(visitor: inout Visitor) throws -> Visitor.Value {
		try visitor.visit(self)
	}
}

struct UnaryExpr: Expr {
	var id: String
	let op: Token
	let expr: any Expr

	func accept<Visitor: ExprVisitor>(visitor: inout Visitor) throws -> Visitor.Value {
		try visitor.visit(self)
	}
}

struct VariableExpr: Expr {
	var id: String
	let name: Token

	func accept<Visitor: ExprVisitor>(visitor: inout Visitor) throws -> Visitor.Value {
		try visitor.visit(self)
	}
}

struct AssignExpr: Expr {
	var id: String
	let name: Token
	var value: any Expr

	func accept<Visitor: ExprVisitor>(visitor: inout Visitor) throws -> Visitor.Value {
		try visitor.visit(self)
	}
}

struct LogicExpr: Expr {
	var id: String
	let lhs: any Expr
	let op: Token
	let rhs: any Expr

	func accept<Visitor: ExprVisitor>(visitor: inout Visitor) throws -> Visitor.Value {
		try visitor.visit(self)
	}
}

struct CallExpr: Expr {
	var id: String
	let callee: any Expr
	let closingParen: Token // For error reporting
	let arguments: [any Expr]

	func accept<Visitor: ExprVisitor>(visitor: inout Visitor) throws -> Visitor.Value {
		try visitor.visit(self)
	}
}

struct GetExpr: Expr {
	var id: String
	let receiver: any Expr
	let name: Token

	func accept<Visitor: ExprVisitor>(visitor: inout Visitor) throws -> Visitor.Value {
		try visitor.visit(self)
	}
}

struct SetExpr: Expr {
	var id: String
	let receiver: any Expr
	let name: Token
	let value: any Expr

	func accept<Visitor: ExprVisitor>(visitor: inout Visitor) throws -> Visitor.Value {
		try visitor.visit(self)
	}
}

struct SelfExpr: Expr {
	var id: String
	var token: Token

	func accept<Visitor: ExprVisitor>(visitor: inout Visitor) throws -> Visitor.Value {
		try visitor.visit(self)
	}
}
