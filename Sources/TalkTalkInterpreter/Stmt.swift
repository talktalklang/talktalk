protocol StmtVisitor {
	func visit(_ stmt: PrintStmt) throws
	func visit(_ stmt: ExpressionStmt) throws
	func visit(_ stmt: VarStmt) throws
	func visit(_ stmt: BlockStmt) throws
	func visit(_ stmt: IfStmt) throws
	func visit(_ stmt: WhileStmt) throws
	func visit(_ stmt: FunctionStmt) throws
	func visit(_ stmt: ReturnStmt) throws
	func visit(_ stmt: ClassStmt) throws
}

protocol Stmt: Sendable {
	func accept<Visitor: StmtVisitor>(visitor: Visitor) throws
}

struct PrintStmt: Stmt {
	let expr: any Expr

	func accept<Visitor: StmtVisitor>(visitor: Visitor) throws {
		try visitor.visit(self)
	}
}

struct ExpressionStmt: Stmt {
	let expr: any Expr

	func accept<Visitor: StmtVisitor>(visitor: Visitor) throws {
		try visitor.visit(self)
	}
}

struct VarStmt: Stmt {
	let name: Token
	let initializer: (any Expr)?

	func accept<Visitor: StmtVisitor>(visitor: Visitor) throws {
		try visitor.visit(self)
	}
}

struct BlockStmt: Stmt {
	let statements: [any Stmt]

	func accept<Visitor: StmtVisitor>(visitor: Visitor) throws {
		try visitor.visit(self)
	}
}

struct IfStmt: Stmt {
	let condition: any Expr
	let thenStatement: any Stmt
	let elseStatement: (any Stmt)?

	func accept<Visitor: StmtVisitor>(visitor: Visitor) throws {
		try visitor.visit(self)
	}
}

struct WhileStmt: Stmt {
	let condition: any Expr
	let body: [any Stmt]

	func accept<Visitor: StmtVisitor>(visitor: Visitor) throws {
		try visitor.visit(self)
	}
}

struct FunctionStmt: Stmt, Identifiable {
	let id: String
	let name: Token
	let params: [Token]
	let body: [any Stmt]

	func accept<Visitor: StmtVisitor>(visitor: Visitor) throws {
		try visitor.visit(self)
	}
}

struct ReturnStmt: Stmt {
	let token: Token
	let value: (any Expr)?

	func accept<Visitor: StmtVisitor>(visitor: Visitor) throws {
		try visitor.visit(self)
	}
}

struct ClassStmt: Stmt {
	let name: Token
	let inits: [FunctionStmt]
	let methods: [FunctionStmt]

	func accept<Visitor: StmtVisitor>(visitor: Visitor) throws {
		try visitor.visit(self)
	}
}
