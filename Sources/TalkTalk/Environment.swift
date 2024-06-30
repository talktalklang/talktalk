class Environment: Equatable {
	static func ==(lhs: Environment, rhs: Environment) -> Bool {
		return lhs.vars == rhs.vars && lhs.parent == rhs.parent
	}

	enum AssignmentResult {
		case handled, unhandled, uninitialized
	}

	private var vars: [String: Value] = [:]
	private var parent: Environment?

	init(parent: Environment? = nil) {
		self.parent = parent
	}

	var description: String {
		"Environment(vars: \(vars.debugDescription), parent: \(parent?.description as Any))"
	}

	func lookup(name: String) -> Value? {
		vars[name] ?? parent?.lookup(name: name)
	}

	func lookup(name: Token, depth: Int) throws -> Value {
		let environment = ancestor(depth: depth)
		return try environment?.lookup(name: name.lexeme) ?? {
			throw RuntimeError.nameError("Undefined variable: \(name)", name)
		}()
	}

	func initialize(name: String, value: Value) {
		vars[name] = value
	}

	func assign(name: Token, value: Value, depth: Int) throws {
		guard let environment = ancestor(depth: depth) else {
			throw RuntimeError.nameError("No environment found at depth: \(depth)", name)
		}

		try environment.assign(name: name.lexeme, value: value)
	}

	func assign(name: String, value: Value) throws {
		if vars.index(forKey: name) != nil {
			vars[name] = value
		} else {
			throw RuntimeError.assignmentError("Cannot assign to uninitialized variable: \(name)")
		}
	}

	func define(name: String, callable: any Callable) {
		vars[name] = .callable(.init(name: name, callable: callable))
	}

	private func ancestor(depth: Int) -> Environment? {
		var environment: Environment? = self

		if depth == 0 {
			return environment
		}

		for _ in 0 ..< depth {
			environment = environment?.parent
		}

		return environment
	}
}
