protocol StmtVisitor {
	mutating func visit(_ stmt: PrintStmt) throws
	mutating func visit(_ stmt: ExpressionStmt) throws
}

protocol Stmt {
	func accept<Visitor: StmtVisitor>(visitor: inout Visitor) throws -> Void
}

struct PrintStmt: Stmt {
	let expr: any Expr

	func accept<Visitor: StmtVisitor>(visitor: inout Visitor) throws {
		try visitor.visit(self)
	}
}

struct ExpressionStmt: Stmt {
	let expr: any Expr

	func accept<Visitor: StmtVisitor>(visitor: inout Visitor) throws {
		try visitor.visit(self)
	}
}
