import TalkTalkSyntax

public struct TypeDef {
	public var name: String
	public var definition: any Syntax

	public func assignable(from other: TypeDef) -> Bool {
		return name == other.name
	}

	public func member(named name: String) -> TypeDef? {
		nil
	}
}

// Builtins
extension TypeDef {
	public static func int(from definition: any Syntax) -> TypeDef {
		TypeDef(name: "Int", definition: definition)
	}

	public static func string(from definition: any Syntax) -> TypeDef {
		TypeDef(name: "String", definition: definition)
	}

	public static func bool(from definition: any Syntax) -> TypeDef {
		TypeDef(name: "Bool", definition: definition)
	}

	public static func array(_ elementDef: TypeDef, from definition: any Syntax) -> TypeDef {
		TypeDef(name: "Array<\(elementDef.name)>", definition: definition)
	}
}
