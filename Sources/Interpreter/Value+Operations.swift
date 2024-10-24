import TalkTalkCore

extension Value {
  func apply(_ op: BinaryOperator, with rhs: Value) throws -> Value {
    switch op {
    case .plus:
      try add(self, rhs)
    case .equalEqual:
      try equals(self, rhs)
    case .bangEqual:
      try bangEqual(self, rhs)
    case .less:
      try less(self, rhs)
    case .lessEqual:
      try lessEqual(self, rhs)
    case .greater:
      try greater(self, rhs)
    case .greaterEqual:
      try greaterEqual(self, rhs)
    case .minus:
      try minus(self, rhs)
    case .star:
      try star(self, rhs)
    case .slash:
      try slash(self, rhs)
    case .percent:
      try percent(self, rhs)
    case .is:
      .nil
    }
  }

  func add(_ lhs: Value, _ rhs: Value) throws -> Value {
    switch (lhs, rhs) {
    case let (.int(lhs), .int(rhs)):
      return .int(lhs + rhs)
    case let (.string(lhs), .string(rhs)):
      return .string(lhs + rhs)
    default:
      throw RuntimeError.invalidOperation("\(lhs) + \(rhs)")
    }
  }

  func minus(_ lhs: Value, _ rhs: Value) throws -> Value {
    switch (lhs, rhs) {
    case let (.int(lhs), .int(rhs)):
      return .int(lhs - rhs)
    default:
      throw RuntimeError.invalidOperation("\(lhs) - \(rhs)")
    }
  }

  func equals(_ lhs: Value, _ rhs: Value) throws -> Value {
    .bool(lhs == rhs)
  }

  func bangEqual(_ lhs: Value, _ rhs: Value) throws -> Value {
    .bool(lhs != rhs)
  }

  func less(_ lhs: Value, _ rhs: Value) throws -> Value {
    switch (lhs, rhs) {
    case let (.int(lhs), .int(rhs)):
      .bool(lhs < rhs)
    default:
      throw RuntimeError.invalidOperation("\(lhs) < \(rhs)")
    }
  }

  func lessEqual(_ lhs: Value, _ rhs: Value) throws -> Value {
    switch (lhs, rhs) {
    case let (.int(lhs), .int(rhs)):
      .bool(lhs <= rhs)
    default:
      throw RuntimeError.invalidOperation("\(lhs) <= \(rhs)")
    }
  }

  func greater(_ lhs: Value, _ rhs: Value) throws -> Value {
    switch (lhs, rhs) {
    case let (.int(lhs), .int(rhs)):
      .bool(lhs > rhs)
    default:
      throw RuntimeError.invalidOperation("\(lhs) > \(rhs)")
    }
  }

  func greaterEqual(_ lhs: Value, _ rhs: Value) throws -> Value {
    switch (lhs, rhs) {
    case let (.int(lhs), .int(rhs)):
      .bool(lhs >= rhs)
    default:
      throw RuntimeError.invalidOperation("\(lhs) > \(rhs)")
    }
  }

  func star(_ lhs: Value, _ rhs: Value) throws -> Value {
    switch (lhs, rhs) {
    case let (.int(lhs), .int(rhs)):
      .int(lhs * rhs)
    default:
      throw RuntimeError.invalidOperation("\(lhs) * \(rhs)")
    }
  }

  func slash(_ lhs: Value, _ rhs: Value) throws -> Value {
    switch (lhs, rhs) {
    case let (.int(lhs), .int(rhs)):
      .int(lhs / rhs)
    default:
      throw RuntimeError.invalidOperation("\(lhs) / \(rhs)")
    }
  }

  func percent(_ lhs: Value, _ rhs: Value) throws -> Value {
    switch (lhs, rhs) {
    case let (.int(lhs), .int(rhs)):
      .int(lhs % rhs)
    default:
      throw RuntimeError.invalidOperation("\(lhs) % \(rhs)")
    }
  }
}
