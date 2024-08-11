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
		[
			_RawArray
		]
	}

	public let name: String
	public let properties: [String: Property]
	public let methods: [String: Method]

	public func slot() -> Byte {
		Byte(Self.list.firstIndex(where: { $0.name == name })!)
	}

	public static func lookup(name: String) -> BuiltinStruct? {
		list.first(where: { $0.name == name })
	}

	static func syntheticExpr() -> any Expr {
		IdentifierExprSyntax(name: "__builtin__", location: [.synthetic(.builtin)])
	}

	static var _RawArray: BuiltinStruct {
		.init(
			name: "_RawArray",
			properties: [
				"count": .init(slot: 0, name: "count", type: .int, expr: syntheticExpr(), isMutable: false)
			],
			methods: [
				"init": .init(slot: 0, name: "init", params: [], type: .instance(.struct("_RawArray")), expr: syntheticExpr()),
				"append": .init(slot: 1, name: "append", params: [], type: .function("append", .void, [.int("element")], []), expr: syntheticExpr())
			]
		)
	}

	func structType() -> StructType {
		.init(name: name, properties: properties, methods: methods)
	}

	func binding() -> Environment.Binding {
		.init(
			name: name,
			expr: Self.syntheticExpr(),
			type: .struct(name),
			isCaptured: false,
			isBuiltin: true,
			isParameter: false,
			isGlobal: false,
			externalModule: nil
		)
	}
}
