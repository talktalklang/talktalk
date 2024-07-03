extension AstInterpreter: StmtVisitor {
	class Instance: @unchecked Sendable, Equatable {
		static func == (lhs: Instance, rhs: Instance) -> Bool {
			return lhs.class == rhs.class && lhs.properties == rhs.properties
		}

		let `class`: Class
		var properties: [String: Value] = [:]

		init(class klass: Class) {
			self.class = klass
		}

		func get(_ name: Token) throws -> Value {
			if let property = properties[name.lexeme] {
				return property
			}

			if let method = self.class.methods[name.lexeme] {
				return try .method(method.bind(to: self))
			}

			return .nil
		}

		func set(_ name: Token, value: Value) {
			properties[name.lexeme] = value
		}
	}

	class Class: Callable, Equatable, @unchecked Sendable {
		static func == (lhs: Class, rhs: Class) -> Bool {
			lhs.name.lexeme == rhs.name.lexeme
		}

		let name: Token
		let inits: [Function]
		let methods: [String: Function]

		init(name: Token, inits: [Function], methods: [String: Function]) {
			self.name = name
			self.inits = inits
			self.methods = methods
		}

		func call(_ context: inout AstInterpreter, arguments: [Value]) throws -> Value {
			let instance = Instance(class: self)

			if let initializer = inits.first(where: { $0.arity == arguments.count }) {
				_ = try initializer.bind(to: instance).call(&context, arguments: arguments)
			}

			return .instance(instance)
		}
	}

	struct Function: Callable, Equatable, @unchecked Sendable {
		static func == (lhs: Function, rhs: Function) -> Bool {
			lhs.functionStmt.id == rhs.functionStmt.id && lhs.closure == rhs.closure
		}

		static let void = Function(
			functionStmt: FunctionStmt(
				id: "_void",
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

		var arity: Int {
			functionStmt.params.count
		}

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

		func bind(to instance: Instance) throws -> Function {
			let environment = Environment(parent: closure)
			try environment.define(name: "self", value: .instance(instance))

			return Function(functionStmt: functionStmt, closure: environment)
		}
	}

	mutating func visit(_ stmt: PrintStmt) throws {
		try output.print(evaluate(stmt.expr))
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

		var methods: [String: Function] = [:]
		for method in stmt.methods {
			let function = Function(functionStmt: method, closure: environment)
			methods[method.name.lexeme] = function
		}

		let inits = stmt.inits.map { initializer in
			Function(functionStmt: initializer, closure: environment)
		}

		let klass = Class(name: stmt.name, inits: inits, methods: methods)
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
