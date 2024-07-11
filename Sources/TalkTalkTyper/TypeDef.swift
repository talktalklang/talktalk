import TalkTalkSyntax

public struct TypeDef {
	public var name: String

	public func assignable(from other: TypeDef) -> Bool {
		return name == other.name
	}

	public func member(named name: String) -> TypeDef? {
		nil
	}
}

// Builtins
extension TypeDef {
	public static var int: TypeDef { TypeDef(name: "Int") }
	public static var string: TypeDef { TypeDef(name: "String") }
	public static var bool: TypeDef { TypeDef(name: "Bool") }

	public static func array(_ elementDef: TypeDef) -> TypeDef {
		TypeDef(name: "Array<\(elementDef.name)>")
	}
}
