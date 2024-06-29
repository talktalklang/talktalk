enum Value: Equatable {
	enum CallError: Error {
		case valueNotCallable(Value)
	}

	case string(String),
			 number(Double),
			 bool(Bool),
			 `nil`,
			 unknown

	func call(_ interpreter: AstInterpreter, _ arguments: [Value]) throws -> Value {
		throw CallError.valueNotCallable(self)
	}
}


