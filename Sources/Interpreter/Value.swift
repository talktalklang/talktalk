import TalkTalkCore

public enum Value: Equatable, CustomStringConvertible {
  case int(Int)
  case string(String)
  case bool(Bool)
	case fn(SyntaxID)
  case `nil`

  var isCallable: Bool {
    if case .fn = self {
      return true
    }

    return false
  }

	public var description: String {
		switch self {
		case .int(let int):
			"\(int)"
		case .string(let string):
			string
		case .bool(let bool):
			"\(bool)"
		case .fn(let closureID):
			"closure \(closureID)"
		case .nil:
			"nil"
		}
	}
}
