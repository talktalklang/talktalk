import TalkTalkSyntax

public struct TypeDef {
	public var name: String
	public var definition: any Syntax

	public func assignable(from other: TypeDef) -> Bool {
		return name == other.name
	}

	public func member(named _: String) -> TypeDef? {
		nil
	}

	// TODO: Temporary until we flesh out type defs some more
	public func returnDef() -> TypeDef {
		guard let returnName = name.firstMatch(of: #/Function<(\w+)>/#) else {
			fatalError("No return def for \(name)")
		}

		return TypeDef(name: String(returnName.output.1), definition: definition)
	}
}

// Builtins
public extension TypeDef {
	static func int(from definition: any Syntax) -> TypeDef {
		TypeDef(name: "Int", definition: definition)
	}

	static func string(from definition: any Syntax) -> TypeDef {
		TypeDef(name: "String", definition: definition)
	}

	static func bool(from definition: any Syntax) -> TypeDef {
		TypeDef(name: "Bool", definition: definition)
	}

	static func array(_ elementDef: TypeDef, from definition: any Syntax) -> TypeDef {
		TypeDef(name: "Array<\(elementDef.name)>", definition: definition)
	}
}
