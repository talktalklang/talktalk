import TalkTalkSyntax

// A TypedValue binds a source location with a type. It also contains
public struct TypedValue {
	public enum Status {
		case declared, defined
	}

	public var type: ValueType
	public var definition: any Syntax
	public var status: Status
	@Boxed public var ref: TypedValue?
	public var environment: CaptureEnvironment?
	public var isEscaping: Bool = false

	init(
		type: ValueType,
		definition: any Syntax,
		ref: TypedValue? = nil,
		status: Status,
		environment: CaptureEnvironment? = nil
	) {
		self.type = type
		self.definition = definition
		self._ref = Boxed(value: ref)
		self.status = status
		self.environment = environment
	}

	public func assignable(from other: TypedValue) -> Bool {
		return type == other.type
	}

	public func member(named _: String) -> TypedValue? {
		nil
	}

	// TODO: Temporary until we flesh out type defs some more
	public func returnDef() -> ValueType {
		guard let returnType = type.returns?.value else {
			fatalError("No return def for \(type)")
		}

		return returnType
	}
}

// Builtins
public extension TypedValue {
	static func int(from definition: any Syntax) -> TypedValue {
		TypedValue(type: .int, definition: definition, status: .defined)
	}

	static func string(from definition: any Syntax) -> TypedValue {
		TypedValue(type: .string, definition: definition, status: .defined)
	}

	static func bool(from definition: any Syntax) -> TypedValue {
		TypedValue(type: .bool, definition: definition, status: .defined)
	}

	static func array(_ elementDef: ValueType, from definition: any Syntax) -> TypedValue {
		TypedValue(type: .array(elementDef), definition: definition, status: .defined)
	}

	static func void(_ node: any Syntax) -> TypedValue {
		TypedValue(type: .void, definition: node, status: .defined)
	}
}
