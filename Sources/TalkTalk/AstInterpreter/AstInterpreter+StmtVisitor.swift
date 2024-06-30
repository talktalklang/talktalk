extension AstInterpreter: StmtVisitor {
	class Class: Callable, Equatable, @unchecked Sendable {
		static func ==(lhs: Class, rhs: Class) -> Bool {
			lhs.name.lexeme == rhs.name.lexeme
		}

		let name: Token
		var properties: [String: Value] = [:]

		init(name: Token) {
			self.name = name
		}

		func call(_ context: inout AstInterpreter, arguments: [Value]) throws -> Value {
			.instance(self)
		}

		func get(_ name: Token) -> Value {
			properties[name.lexeme] ?? .nil
		}

		func set(_ name: Token, value: Value) {
			properties[name.lexeme] = value
		}
	}

	struct Function: Callable, @unchecked Sendable {
		static let `void` = Function(
			functionStmt: FunctionStmt(
				name: Token(kind: .func, lexeme: "_void", line: -1),
				params: [],
				body: []
			),
			closure: Environment()
		)

		enum Return: Error {
			case value(Value)
		}

		let functionStmt: FunctionStmt
		let closure: Environment

		func call(_ context: inout AstInterpreter, arguments: [Value]) throws -> Value {
			let environment = Environment(parent: closure)

			for (i, param) in functionStmt.params.enumerated() {
				environment.initialize(name: param.lexeme, value: arguments[i])
			}

			do {
				try context.executeBlock(functionStmt.body, environment: environment)
			} catch let Return.value(value) {
				return value
			}

			return .nil
		}
	}

	mutating func visit(_ stmt: PrintStmt) throws {
		try print(evaluate(stmt.expr))
	}

	mutating func visit(_ stmt: ExpressionStmt) throws {
		_ = try evaluate(stmt.expr)
	}

	mutating func visit(_ stmt: VarStmt) throws {
		if let initializer = stmt.initializer {
			try environment.initialize(name: stmt.name.lexeme, value: evaluate(initializer))
		} else {
			environment.initialize(name: stmt.name.lexeme, value: .nil)
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
			for statement in stmt.body {
				try execute(statement: statement)
			}
		}
	}

	mutating func visit(_ stmt: FunctionStmt) throws {
		environment.define(
			name: stmt.name.lexeme,
			callable: Function(functionStmt: stmt, closure: environment)
		)
	}

	mutating func visit(_ stmt: ReturnStmt) throws {
		// TODO: Figure out a way to do this without throwing
		if let valueExpr = stmt.value {
			throw try Function.Return.value(evaluate(valueExpr))
		}
	}

	mutating func visit(_ stmt: ClassStmt) throws {
		environment.define(name: stmt.name.lexeme, callable: Function.void)
		let klass = Class(name: stmt.name)
		environment.define(name: stmt.name.lexeme, callable: klass)
	}

	mutating func executeBlock(_ statements: [any Stmt], environment: Environment) throws {
		let previousEnvironment = self.environment

		defer {
			self.environment = previousEnvironment
		}

		self.environment = environment

		for statement in statements {
			try execute(statement: statement)
		}
	}
}
