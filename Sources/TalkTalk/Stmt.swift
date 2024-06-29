protocol StmtVisitor {
	mutating func visit(_ stmt: PrintStmt) throws
	mutating func visit(_ stmt: ExpressionStmt) throws
	mutating func visit(_ stmt: VarStmt) throws
	mutating func visit(_ stmt: BlockStmt) throws
	mutating func visit(_ stmt: IfStmt) throws
	mutating func visit(_ stmt: WhileStmt) throws
	mutating func visit(_ stmt: FunctionStmt) throws
	mutating func visit(_ stmt: ReturnStmt) throws
}

protocol Stmt: Sendable {
	func accept<Visitor: StmtVisitor>(visitor: inout Visitor) throws
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

struct VarStmt: Stmt {
	let name: String
	let initializer: (any Expr)?

	func accept<Visitor: StmtVisitor>(visitor: inout Visitor) throws {
		try visitor.visit(self)
	}
}

struct BlockStmt: Stmt {
	let statements: [any Stmt]

	func accept<Visitor: StmtVisitor>(visitor: inout Visitor) throws {
		try visitor.visit(self)
	}
}

struct IfStmt: Stmt {
	let condition: any Expr
	let thenStatement: any Stmt
	let elseStatement: (any Stmt)?

	func accept<Visitor: StmtVisitor>(visitor: inout Visitor) throws {
		try visitor.visit(self)
	}
}

struct WhileStmt: Stmt {
	let condition: any Expr
	let statements: [any Stmt]

	func accept<Visitor: StmtVisitor>(visitor: inout Visitor) throws {
		try visitor.visit(self)
	}
}

struct FunctionStmt: Stmt {
	let name: Token
	let params: [Token]
	let body: [any Stmt]

	func accept<Visitor: StmtVisitor>(visitor: inout Visitor) throws {
		try visitor.visit(self)
	}
}

struct ReturnStmt: Stmt {
	let value: (any Expr)?

	func accept<Visitor: StmtVisitor>(visitor: inout Visitor) throws {
		try visitor.visit(self)
	}
}
