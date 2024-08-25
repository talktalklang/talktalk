//
//  BuiltinStruct.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/10/24.
//

import TalkTalkBytecode
import TalkTalkSyntax

public struct BuiltinStruct {
	public static var list: [BuiltinStruct] {
		[]
	}

	public let name: String
	public let properties: [String: Property]
	public let methods: [String: Method]
	public let typeParameters: [TypeParameter]

	public func slot() -> Byte {
		Byte(Self.list.firstIndex(where: { $0.name == name })!)
	}

	public static func lookup(name: String) -> BuiltinStruct? {
		list.first(where: { $0.name == name })
	}

	static func syntheticExpr() -> any Expr {
		IdentifierExprSyntax(id: -4, name: "__builtin__", location: [.synthetic(.builtin)])
	}

	func structType() -> StructType {
		.init(name: name, properties: properties, methods: methods, typeParameters: typeParameters)
	}

	func binding(in _: Environment) -> Environment.Binding {
		.init(
			name: name,
			expr: Self.syntheticExpr(),
			type: TypeID(.struct(name)),
			isCaptured: false,
			isBuiltin: true,
			isParameter: false,
			isGlobal: false,
			externalModule: nil
		)
	}
}
