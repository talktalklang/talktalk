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
	private var parent: Parent?

	init(parent: Environment? = nil) {
		if let parent {
			self.parent = Parent(environment: parent)
		}
	}

	func lookup(name: String) -> Value? {
		vars[name] ?? parent?.environment.lookup(name: name)
	}

	func initialize(name: String, value: Value) {
		vars[name] = value
	}

	func assign(name: String, value: Value) throws -> AssignmentResult {
		if try parent?.environment.assign(name: name, value: value) == .handled {
			return .handled
		}

		guard lookup(name: name) != nil else {
			throw RuntimeError.assignmentError("Cannot assign to uninitialized variable")
		}

		vars[name] = value

		return .handled
	}

	func define(name: String, callable: any Callable) {
		vars[name] = .callable(.init(name: name, callable: callable))
	}
}


