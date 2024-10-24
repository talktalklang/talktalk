import TalkTalkCore

extension Value {
  func call(with args: [Value], interpreter: Interpreter, in context: InterpreterContext) throws -> ReturnValue {
    switch self {
    case let .fn(closureID):
			guard let (syntax, closure) = context.closure(closureID) else {
				throw RuntimeError.missingValue("closure not found for syntax id \(closureID)")
			}

      let childContext = closure.child()

			for (param, arg) in zip(syntax.params.params, args) {
				childContext.bind(param.name, to: arg)
			}

			if let name = syntax.name?.lexeme {
				childContext.bind(name, to: self)
			}

			let returning = try interpreter.visit(syntax.body, childContext)

			// We don't want to propogate returns past their callers
			switch returning {
			case let .returning(.fn(id)), let .value(.fn(id)):
				if let closure = childContext.closure(id) {
					_ = context.defineClosure(syntax: closure.0, closure: closure.1)
				}

				return .value(.fn(id))
			case .value(let value):
				return .value(value)
			case .returning(let value):
				return .value(value)
			case .void:
				return .void
			}
    default:
      return .void
    }
  }
}
