struct CallableWrapper: Equatable, Sendable {
	static func ==(lhs: CallableWrapper, rhs: CallableWrapper) -> Bool {
		lhs.name == rhs.name
	}

	var name: String
	var callable: any Callable
}

protocol Callable: Sendable {
	func call(_ context: inout AstInterpreter, arguments: [Value]) throws -> Value
}
