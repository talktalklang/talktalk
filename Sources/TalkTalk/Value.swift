enum Value: Sendable, Equatable {
	enum CallError: Error {
		case valueNotCallable(Value)
	}

	case string(String),
	     number(Double),
	     bool(Bool),
	     `nil`,
	     callable(CallableWrapper),
	     void,
	     unknown

	func call(_ interpreter: inout AstInterpreter, _ arguments: [Value]) throws -> Value {
		if case let .callable(wrapper) = self {
			return try wrapper.callable.call(&interpreter, arguments: arguments)
		} else {
			throw CallError.valueNotCallable(self)
		}
	}
}
