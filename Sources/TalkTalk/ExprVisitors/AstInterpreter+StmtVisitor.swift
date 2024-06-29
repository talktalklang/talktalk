extension AstInterpreter: StmtVisitor {
	mutating func visit(_ stmt: PrintStmt) throws {
		try print(evaluate(stmt.expr))
	}

	mutating func visit(_ stmt: ExpressionStmt) throws {
		_ = try evaluate(stmt.expr)
	}

	mutating func visit(_ stmt: VarStmt) throws {
		if let initializer = stmt.initializer {
			environment.initialize(name: stmt.name, value: try evaluate(initializer))
		} else {
			environment.initialize(name: stmt.name, value: .nil)
		}
	}

	mutating func visit(_ stmt: BlockStmt) throws {
		try executeBlock(stmt.statements, environment: Environment(parent: environment))
	}

	mutating func visit(_ stmt: IfStmt) throws {
		if try isTruthy(evaluate(stmt.condition)) {
			try execute(statement: stmt.thenStatement)
		} else if let elseStatement = stmt.elseStatement {
			try execute(statement: elseStatement)
		}
	}

	mutating func visit(_ stmt: WhileStmt) throws {
		while try isTruthy(evaluate(stmt.condition)) {
			for statement in stmt.statements {
				try execute(statement: statement)
			}
		}
	}

	mutating func executeBlock(_ statements: [any Stmt], environment: Environment) throws {
		defer {
			_ = environmentStack.popLast()
		}

		environmentStack.append(environment)

		for statement in statements {
			try	execute(statement: statement)
		}
	}
}
