class Environment {
	enum AssignmentResult {
		case handled, unhandled, uninitialized
	}

	final class Parent {
		var environment: Environment

		init(environment: Environment) {
			self.environment = environment
		}
	}

	private var vars: [String: Value] = [:]
	private var parent: Environment?

	init(parent: Environment? = nil) {
		self.parent = parent
	}

	func lookup(name: String) -> Value? {
		vars[name] ?? parent?.lookup(name: name)
	}

	func initialize(name: String, value: Value) {
		vars[name] = value
	}

	func assign(name: String, value: Value) throws -> AssignmentResult {
		if vars.index(forKey: name) != nil {
			vars[name] = value
			return .handled
		}

		if try parent?.assign(name: name, value: value) == .handled {
			return .handled
		}

		throw RuntimeError.assignmentError("Cannot assign to uninitialized variable")
	}

	func define(name: String, callable: any Callable) {
		vars[name] = .callable(.init(name: name, callable: callable))
	}
}


